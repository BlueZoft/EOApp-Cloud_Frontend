#!/usr/bin/env python3
"""Disposable local HTTPS rehearsal. Never uses production .env.deploy or data."""
import argparse
import base64
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import ssl
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--no-build', action='store_true', help='Use previously built eoapp-{api,web}:<release-tag> images')
    parser.add_argument('--release-tag', default='deploy-validation')
    parser.add_argument('--docker-host', help='Optional Docker engine endpoint; use the same endpoint used for builds')
    args = parser.parse_args()
    docker = ['docker'] + (['--host', args.docker_host] if args.docker_host else [])
    if not shutil.which('node') or not shutil.which('openssl'):
        raise SystemExit('Node 22+ and OpenSSL are required for this optional rehearsal.')
    if not (Path(__file__).parent / 'node_modules/playwright').exists():
        raise SystemExit('First run: npm ci --prefix deploy/qa')
    if not (ROOT / 'build/web/deployment.json').exists():
        raise SystemExit('Build the same-origin web bundle with scripts/build-web-deploy.sh first.')
    project = 'eoapp-qa-' + uuid.uuid4().hex[:10]
    with tempfile.TemporaryDirectory(prefix='eoapp-https-') as temporary:
        folder = Path(temporary)
        tls = folder / 'tls'
        tls.mkdir(mode=0o750)
        tls.chmod(0o750)  # A restrictive host umask must not remove group traversal.
        # Only disposable test keys; private key is group-readable for nginx's
        # supplementary test group, never world-readable or committed.
        def openssl(*items):
            subprocess.run(['openssl', *map(str, items)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ca = folder / 'ca.pem'
        openssl('req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-keyout', folder/'ca-key.pem', '-out', ca, '-subj', '/CN=EOApp disposable deployment test CA')
        openssl('req', '-newkey', 'rsa:2048', '-nodes', '-keyout', tls/'privkey.pem', '-out', folder/'server.csr', '-subj', '/CN=localhost')
        (folder/'server.ext').write_text('subjectAltName=DNS:localhost,IP:127.0.0.1\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n')
        openssl('x509', '-req', '-in', folder/'server.csr', '-CA', ca, '-CAkey', folder/'ca-key.pem', '-CAcreateserial', '-days', '1', '-extfile', folder/'server.ext', '-out', folder/'leaf.pem')
        (tls/'fullchain.pem').write_bytes((folder/'leaf.pem').read_bytes() + ca.read_bytes())
        (tls/'privkey.pem').chmod(0o640)
        (tls/'fullchain.pem').chmod(0o640)
        # Docker sees the mounted TLS directory directly, not its private parent.
        def free_port():
            with socket.socket() as sock:
                sock.bind(('127.0.0.1', 0))
                return sock.getsockname()[1]
        https_port = free_port()
        http_port = free_port()
        while http_port == https_port:
            http_port = free_port()
        origin = f'https://localhost:{https_port}'
        mount_gid = subprocess.check_output(docker + ['run', '--rm', '--mount', f'type=bind,src={tls},dst=/probe,readonly',
            'node:22-alpine', 'node', '-e', "console.log(require('fs').statSync('/probe/privkey.pem').gid)"], text=True).strip()
        if not mount_gid.isdigit():
            raise RuntimeError('Could not determine the container-visible TLS group')
        values = {
            'SERVER_NAME': 'localhost', 'PUBLIC_ORIGIN': origin,
            'MONGO_URI': 'mongodb://test-db:27017/eoapp_deployment_test',
            'BACKEND_CONTEXT': str(ROOT.parent / 'EOApp-Cloud_Backend'),
            'TLS_CERT_DIR': str(tls), 'TLS_READ_GID': mount_gid,
            'HTTP_BIND': f'127.0.0.1:{http_port}', 'HTTPS_BIND': f'127.0.0.1:{https_port}',
            'RELEASE_TAG': args.release_tag, 'SMTP_ENABLED': 'false', 'STAFF_ENABLED': 'true',
            'SMTP_HOST': '', 'SMTP_USER': '', 'SMTP_PASSWORD': '', 'SMTP_FROM': '', 'SMTP_TO': '', 'SMTP_PORT': '465',
        }
        test_env = os.environ.copy()
        test_env.update(values)  # Never inherit a production URI or enabled SMTP.
        if args.docker_host:
            for key in ['DOCKER_HOST', 'DOCKER_CONTEXT', 'DOCKER_TLS', 'DOCKER_TLS_VERIFY', 'DOCKER_CERT_PATH']:
                test_env.pop(key, None)
        env_file = folder/'test.env'
        env_file.write_text(''.join(f'{key}={json.dumps(value)}\n' for key, value in values.items()))
        env_file.chmod(0o600)
        override = folder/'test.override.json'
        override.write_text(json.dumps({'services': {
            'test-db': {'image': 'mongo:7.0', 'healthcheck': {
                'test': ['CMD', 'mongosh', '--quiet', '--eval', 'quit(db.runCommand({ping:1}).ok ? 0 : 1)'],
                'interval': '2s', 'timeout': '5s', 'retries': 20},
                'networks': ['application'], 'volumes': ['qa-data:/data/db']},
            'api': {'depends_on': {'test-db': {'condition': 'service_healthy'}}},
        }, 'volumes': {'qa-data': {}}}))
        compose = docker + ['compose', '--env-file', str(env_file), '-p', project,
            '-f', str(ROOT/'deploy/compose.yaml'), '-f', str(override)]
        def run(*items, **kwargs):
            return subprocess.run(compose + list(items), check=True, env=test_env, **kwargs)
        def request(method, path, body=None, headers=None):
            connection = http.client.HTTPSConnection('localhost', https_port, context=ssl.create_default_context(cafile=str(ca)), timeout=10)
            connection.request(method, path, body=json.dumps(body) if body is not None else None, headers=headers or {})
            response = connection.getresponse()
            content = response.read()
            result = (response.status, dict(response.getheaders()), content)
            connection.close()
            return result
        started = False
        try:
            run('config', '--quiet')
            if not args.no_build:
                run('build')
            started = True
            run('up', '-d', '--no-build', '--wait', '--wait-timeout', '120')
            assert request('GET', '/api/ready')[0] == 200
            status, headers, content = request('GET', '/deployment.json')
            assert status == 200 and json.loads(content)['apiMode'] == 'same-origin'
            lowered = {key.lower(): value for key, value in headers.items()}
            for header in ['strict-transport-security', 'content-security-policy', 'x-content-type-options']:
                assert header in lowered, header
            for path in ['/.env.deploy', '/config/production.json', '/assets/not-a-real-file.js']:
                assert request('GET', path)[0] == 404, path
            status, _, content = request('GET', '/api/not-a-route')
            assert status == 404 and json.loads(content)['error']['code'] == 'NOT_FOUND'
            plain = http.client.HTTPConnection('localhost', http_port, timeout=5)
            plain.request('GET', '/test-route?check=1')
            redirected = plain.getresponse()
            assert redirected.status == 308 and redirected.getheader('Location') == origin+'/test-route?check=1'
            redirected.read(); plain.close()
            directory = {'institutions': [{'code': 'qa-institution', 'name': 'Synthetic deployment institution', 'notificationEmail': 'test-team@local.test'}],
                'rules': [{'loanId': 'general', 'branchId': '*', 'institutionCode': 'qa-institution'}]}
            run('exec', '-T', 'api', 'node', 'scripts/staff.js', 'import-directory', '--file', '/dev/stdin', input=json.dumps(directory), text=True, stdout=subprocess.DEVNULL)
            password = 'qa-' + secrets.token_urlsafe(24)
            run('exec', '-T', 'api', 'node', 'scripts/staff.js', 'provision', '--email', 'officer@local.test', '--name', 'Synthetic Test Officer', '--role', 'officer', '--institution', 'qa-institution', input=password, text=True, stdout=subprocess.DEVNULL)
            public_key = subprocess.check_output(['openssl', 'x509', '-in', str(folder/'leaf.pem'), '-pubkey', '-noout'])
            der = subprocess.check_output(['openssl', 'pkey', '-pubin', '-outform', 'DER'], input=public_key)
            pin = base64.b64encode(hashlib.sha256(der).digest()).decode('ascii')
            environment = test_env.copy()
            environment.update(DEPLOY_BASE_URL=origin, DEPLOY_TEST_PASSWORD=password,
                DEPLOY_TEST_SPKI=pin, NODE_EXTRA_CA_CERTS=str(ca))
            subprocess.run(['node', str(Path(__file__).with_name('check-browser.cjs'))], env=environment, check=True)
            for service, expected_uid in [('api', '1000'), ('web', '101')]:
                result = run('exec', '-T', service, 'id', '-u', capture_output=True, text=True)
                assert result.stdout.strip() == expected_uid
            api_id = run('ps', '-q', 'api', capture_output=True, text=True).stdout.strip()
            bindings = subprocess.check_output(docker + ['inspect', '--format', '{{json .HostConfig.PortBindings}}', api_id], text=True, env=test_env)
            assert json.loads(bindings) in (None, {})
            print('PASS: isolated HTTPS stack, certificate verification, redirect, headers/CSP, private API, browser workflow and non-root containers')
        except Exception:
            if started:
                subprocess.run(compose + ['logs', '--tail', '20', 'api', 'web'], env=test_env)
                ids = subprocess.run(compose + ['ps', '-aq'], env=test_env, capture_output=True, text=True).stdout.split()
                for container in ids:
                    result = subprocess.run(docker + ['inspect', '--format', '{{json .State.Health}}', container], env=test_env, capture_output=True, text=True)
                    health = json.loads(result.stdout or 'null')
                    if health and health.get('Status') != 'healthy':
                        print('Health check failure:', [item.get('Output', '') for item in health.get('Log', [])][-2:])
            raise
        finally:
            if started:
                # This UUID-named project owns the disposable volume. Never use
                # production project names or down --volumes on production data.
                subprocess.run(compose + ['down', '--volumes', '--remove-orphans'], check=True, env=test_env)


if __name__ == '__main__':
    main()
