import copy
import json
from pathlib import Path
import tempfile
import unittest
from synthetic_profile import load_profile


class SyntheticBoundaryTests(unittest.TestCase):
    def test_rejects_real_mailboxes_and_missing_synthetic_marker(self):
        original = json.loads((Path(__file__).resolve().parents[1]/'synthetic/profile.json').read_text())
        variants = []
        missing = copy.deepcopy(original)
        missing['synthetic'] = False
        variants.append(missing)
        real = copy.deepcopy(original)
        real['directory']['institutions'][0]['notificationEmail'] = 'someone@real-company.com'
        variants.append(real)
        wrong = copy.deepcopy(original)
        wrong['directory']['rules'][0]['institutionCode'] = 'missing'
        variants.append(wrong)
        for profile in variants:
            with self.subTest(profile=profile['directory']['rules'][0]['institutionCode']), tempfile.TemporaryDirectory() as directory:
                path = Path(directory)/'profile.json'
                path.write_text(json.dumps(profile))
                with self.assertRaises(ValueError):
                    load_profile(path)


if __name__ == '__main__':
    unittest.main()
