#!/usr/bin/env python3
"""Build a locally signed SYNTHETIC AAB. Never uses/replaces production keys."""
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    def java_tool(name):
        return str(Path(os.environ['JAVA_HOME'])/'bin'/name) if os.environ.get('JAVA_HOME') else name
    profile = json.loads((ROOT/'deploy/synthetic/profile.json').read_text())
    identity = profile['native']['applicationId']
    if profile.get('synthetic') is not True or not identity.startswith('org.example.'):
        raise SystemExit('Synthetic packaging requires an org.example.* test identity')
    folder = ROOT/'deploy/.synthetic-android'
    folder.mkdir(mode=0o700, exist_ok=True)
    signing = folder/'key.properties'
    key = folder/'synthetic-only.p12'
    if not signing.exists():
        if key.exists():
            raise SystemExit('Orphan synthetic key exists; inspect it before retrying')
        password = secrets.token_urlsafe(32)
        environment = os.environ.copy()
        environment['EOAPP_SYNTHETIC_KEY_PASSWORD'] = password
        subprocess.run([java_tool('keytool'), '-genkeypair', '-noprompt', '-keystore', str(key), '-storetype', 'PKCS12',
            '-storepass:env', 'EOAPP_SYNTHETIC_KEY_PASSWORD', '-keypass:env', 'EOAPP_SYNTHETIC_KEY_PASSWORD',
            '-alias', 'synthetic-only', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '30',
            '-dname', 'CN=SYNTHETIC ONLY,OU=Local rehearsal,O=Example,C=LK'], check=True, env=environment)
        key.chmod(0o600)
        signing.write_text(f'applicationId={identity}\nstoreFile={key}\nstorePassword={password}\nkeyAlias=synthetic-only\nkeyPassword={password}\n')
        signing.chmod(0o600)
    elif not key.exists() or f'applicationId={identity}\n' not in signing.read_text():
        raise SystemExit('Existing synthetic identity differs; preserve/inspect it before retrying')
    environment = os.environ.copy()
    environment['EOAPP_SIGNING_PROPERTIES'] = str(signing)
    flutter = os.environ.get('FLUTTER_BIN', 'flutter')
    subprocess.run([flutter, 'build', 'appbundle', '--release', '--no-pub',
        '--dart-define=API_BASE_URL=' + profile['native']['apiBaseUrl']], cwd=ROOT, env=environment, check=True)
    bundle = ROOT/'build/app/outputs/bundle/release/app-release.aab'
    target = folder/'synthetic-only.aab'
    shutil.copyfile(bundle, target)
    with zipfile.ZipFile(target) as archive:
        if identity.encode() not in archive.read('base/manifest/AndroidManifest.xml'):
            raise SystemExit('Bundle manifest does not contain the synthetic application ID')
    verified = subprocess.run([java_tool('jarsigner'), '-verify', str(target)], check=True, capture_output=True, text=True)
    if 'jar verified.' not in verified.stdout:
        raise SystemExit('Bundle signature verification did not report success')
    certificate = subprocess.check_output([java_tool('keytool'), '-printcert', '-jarfile', str(target)], text=True)
    if 'CN=SYNTHETIC ONLY' not in certificate:
        raise SystemExit('Bundle was not signed by the generated synthetic identity')
    report = {'synthetic': True, 'applicationId': identity, 'apiBaseUrl': profile['native']['apiBaseUrl'],
        'artifact': target.name, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'signatureVerified': True, 'deviceTested': False, 'storePublished': False,
        'note': '30-day self-signed test key; not a production signing identity. No native trust override is added.'}
    (folder/'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: synthetic signed Android bundle and signature verification. Artifact/report:', folder)


if __name__ == '__main__':
    main()
