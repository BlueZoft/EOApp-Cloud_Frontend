"""Validate the deliberately narrow local rehearsal fixture contract."""
import json
from pathlib import Path


def load_profile(path):
    profile = json.loads(Path(path).read_text())
    if profile.get('synthetic') is not True:
        raise ValueError('Rehearsal profile must explicitly declare synthetic=true')
    directory = profile['directory']
    codes = {item['code'] for item in directory['institutions']}
    emails = [item['notificationEmail'] for item in directory['institutions']]
    emails += [item['email'] for item in profile['staff']]
    emails += [profile['applicant']['email'], profile['operations']['alertMailbox']]
    if not all(value.endswith('@demo.test') for value in emails):
        raise ValueError('Synthetic addresses must use @demo.test; never use real mailboxes')
    if len(codes) < 2 or len(codes) != len(directory['institutions']):
        raise ValueError('Supply at least two distinct synthetic institutions')
    officers = [item for item in profile['staff'] if item['role'] == 'officer']
    if not officers or not any(item['role'] == 'admin' for item in profile['staff']):
        raise ValueError('Supply synthetic officers and an administrator')
    if profile['staff'][0]['role'] != 'officer' or len({item['email'] for item in profile['staff']}) != len(profile['staff']):
        raise ValueError('The first staff entry must be an officer; staff emails must be unique')
    if any(item['institution'] not in codes for item in officers):
        raise ValueError('Officers must belong to a supplied synthetic institution')
    applicant = profile['applicant']
    if applicant['loanId'] != 'general' or applicant['sex'] != 'female':
        raise ValueError('The browser rehearsal currently exercises a general, female applicant')
    if not any(rule == {'loanId': 'general', 'branchId': '*', 'institutionCode': officers[0]['institution']} for rule in directory['rules']):
        raise ValueError('Route general inquiries to the first synthetic officer institution')
    if not isinstance(profile['operations']['retentionDays'], int) or not 1 <= profile['operations']['retentionDays'] <= 365:
        raise ValueError('Synthetic retentionDays must be 1–365')
    return profile
