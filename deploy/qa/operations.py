"""Operations rehearsal restricted to the runner's disposable database."""
import hashlib
import json
import subprocess
import time

DATABASE = 'eoapp_deployment_test'


def rehearse(run, folder, profile, receipt, request):
    def mongo(script):
        result = run('exec', '-T', 'test-db', 'mongosh', '--quiet', DATABASE, '--eval', script, capture_output=True, text=True)
        return json.loads(result.stdout.strip())

    # Confirm real authenticated STARTTLS transport and durable worker state.
    reference = receipt['reference']
    for attempt in range(60):
        result = run('exec', '-T', 'api', 'node', '-e',
            "fetch('http://test-smtp:8081/messages').then(r=>r.text()).then(console.log)", capture_output=True, text=True)
        messages = json.loads(result.stdout)['messages']
        sent = mongo(f'print(JSON.stringify(db.users.findOne({{_id:ObjectId({json.dumps(reference)})}}).notification.status))')
        if len(messages) == 1 and sent == 'sent':
            break
        time.sleep(0.5)
    else:
        raise RuntimeError('Synthetic TLS email was not delivered and persisted as sent')
    expected_recipient = next(item['notificationEmail'] for item in profile['directory']['institutions']
                              if item['code'] == profile['staff'][0]['institution'])
    assert messages == [{'to': [expected_recipient], 'reference': reference, 'tls': True, 'authenticated': True}], messages

    # Only mutate a clearly marked test probe copied inside the throwaway DB.
    days = profile['operations']['retentionDays']
    retention = mongo(f'''
if (db.getName() !== '{DATABASE}') throw Error('Synthetic database only');
const sample = db.users.findOne({{_id:ObjectId({json.dumps(reference)})}});
sample._id = new ObjectId(); sample.submissionKey = 'synthetic-retention-probe';
sample.createdAt = new Date(Date.now() - {days + 1} * 86400000);
sample.notification = {{status:'disabled',attempts:0}};
db.users.insertOne(sample);
const filter = {{submissionKey:'synthetic-retention-probe',createdAt:{{$lt:new Date(Date.now() - {days} * 86400000)}}}};
const dryRun = db.users.countDocuments(filter);
const deleted = db.users.deleteMany(filter).deletedCount;
print(JSON.stringify({{dryRun,deleted,preserved:db.users.countDocuments({{_id:ObjectId({json.dumps(reference)})}})}}));
''')
    assert retention == {'dryRun': 1, 'deleted': 1, 'preserved': 1}

    backup = folder / 'synthetic-backup.archive.gz'
    result = run('exec', '-T', 'test-db', 'mongodump', '--quiet', '--db', DATABASE, '--archive', '--gzip', capture_output=True)
    backup.write_bytes(result.stdout)
    backup.chmod(0o600)
    assert backup.stat().st_size > 0
    restored = DATABASE + '_restore'
    run('exec', '-T', 'test-db', 'mongorestore', '--quiet', '--archive', '--gzip',
        '--nsInclude', DATABASE + '.*', '--nsFrom', DATABASE + '.*', '--nsTo', restored + '.*',
        input=backup.read_bytes(), stdout=subprocess.DEVNULL)
    verified = mongo(f'''
const target=db.getSiblingDB('{restored}');
const names=db.getCollectionNames().sort();
let matching=names.every(name=>db.getCollection(name).countDocuments({{}})===target.getCollection(name).countDocuments({{}}));
const source=db.users.findOne({{_id:ObjectId({json.dumps(reference)})}});
const copy=target.users.findOne({{_id:source._id}});
matching=matching && EJSON.stringify(source)===EJSON.stringify(copy);
const indexRestored=target.users.getIndexes().some(index=>index.unique && index.key.submissionKey===1);
print(JSON.stringify({{matching,indexRestored,collections:names.length}}));
void target.dropDatabase();
''')
    assert verified['matching'] and verified['indexRestored'] and verified['collections'] >= 5

    # Exercise a real local outage and restart, recording the alert locally.
    # This never sends an operational message to an external destination.
    status, _, _ = request('GET', '/api/ready')
    queue = mongo("print(JSON.stringify({pending:db.users.countDocuments({'notification.status':'pending'}),processing:db.users.countDocuments({'notification.status':'processing'})}))")
    assert status == 200 and queue == {'pending': 0, 'processing': 0}
    healthy = {'ready': status == 200, 'pending': queue['pending'], 'processing': queue['processing']}
    run('stop', 'api', stdout=subprocess.DEVNULL)
    outage_status, _, _ = request('GET', '/api/ready')
    assert outage_status in (502, 503, 504)
    run('start', 'api', stdout=subprocess.DEVNULL)
    for attempt in range(60):
        if request('GET', '/api/ready')[0] == 200:
            break
        time.sleep(0.5)
    else:
        raise RuntimeError('Synthetic API did not recover after restart')
    run('up', '-d', '--no-build', '--wait', '--wait-timeout', '60', stdout=subprocess.DEVNULL)
    assert mongo(f'print(JSON.stringify(db.users.countDocuments({{_id:ObjectId({json.dumps(reference)})}})))') == 1
    expiry_warning = subprocess.run(['openssl', 'x509', '-checkend', '172800', '-noout', '-in', str(folder/'leaf.pem')], capture_output=True).returncode
    assert expiry_warning == 1  # One-day synthetic certificate warns at 48h.
    run('exec', '-T', 'web', 'nginx', '-t', stdout=subprocess.DEVNULL)
    run('exec', '-T', 'web', 'nginx', '-s', 'reload', stdout=subprocess.DEVNULL)
    assert request('GET', '/api/ready')[0] == 200
    report = {
        'synthetic': True, 'smtp': {'authenticatedStartTls': True, 'messages': len(messages), 'recipient': expected_recipient},
        'backup': {'sha256': hashlib.sha256(backup.read_bytes()).hexdigest(), 'restoreVerified': verified},
        'retention': {'days': days, **retention},
        'monitoring': {'sample': healthy, 'observedOutageHttpStatus': outage_status, 'restartRecovered': True,
                       'certificateExpiryWarningAt48h': True, 'nginxReloadVerified': True, 'destination': 'local report only'},
        'policy': profile['operations'],
    }
    (folder / 'operations-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: authenticated STARTTLS capture, routed recipient, backup/restore with unique index, synthetic retention and local alert simulation')
    return report
