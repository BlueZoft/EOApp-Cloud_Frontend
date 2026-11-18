# Prototype handoff — frontend 1.3.2 / backend 1.2.2

The prototype implements credit-scheme discovery, comparison, guided inquiry preparation, inquiry receipt and institutional follow-up. It can be demonstrated with replaceable synthetic data on the local HTTPS stack. The original catalogue remains unchanged; current availability and financial eligibility are not verified.

## Start the demonstration

Follow [synthetic setup](../deploy/synthetic/README.md). The existing published toolchain and prebuilt images can be reused on the managed cloud host:

```sh
CHROMIUM_EXECUTABLE=/usr/bin/chromium python3 deploy/qa/run.py --keep \
  --no-build --release-tag deploy-validation \
  --docker-host unix:///var/run/docker.sock
```

If a previous demo exists, inspect its reports first. `python3 deploy/qa/run.py --stop` removes only that synthetic project and its data before recreating it. The certificates last one day, so an old demo may need recreation. The normal production `.env.deploy` and development MongoDB container are separate.

Read the generated loopback origin and random account passwords locally in ignored `deploy/.synthetic/credentials.json`. Use the generated CA in a disposable client profile; the local certificate is not publicly trusted. The runner itself verifies TLS and exercises the browser automatically. No real credentials are needed for the demonstration.

## Customer walkthrough

1. Choose Sinhala, English or Tamil. The interface changes language; original scheme and branch descriptions remain Sinhala.
2. Select **Get started**, search all schemes or choose a purpose. Compare two or three schemes, then open their original terms.
3. Open the preparation guide or select a scheme. General inquiries are available through **My purpose is not listed**.
4. Fill the inquiry using `deploy/synthetic/profile.json` applicant fields, choose its branch and confirm contact consent.
5. Submit and retain the displayed reference. The reference also has an accessible label. A retry with the original key/payload returns the same receipt.

The profile's numeric identity/telephone values are synthetic format examples. Do not contact them. The demo routes general inquiries to the fictional Enterprise team and loan-01 to the fictional Growth team. Capture accepts only `@demo.test` recipients and cannot relay external email.

## Staff walkthrough

Open **Officer inbox** on the web welcome screen. The generated accounts are `officer@demo.test`, `growth-officer@demo.test` and `admin@demo.test`; use their generated passwords from the local credentials file.

The Enterprise officer can open the general inquiry and change its follow-up status. The Growth officer cannot read that inquiry. The administrator can review both institutions. Sign out and confirm that the session is revoked. These are web staff workflows; native staff sessions are outside this prototype's implemented scope.

## Evidence and operating demonstration

The completed runner writes `browser-report.json`, `operations-report.json`, a protected synthetic database backup, an inquiry-receipt image and three mobile-width welcome images under ignored `deploy/.synthetic/`.

The browser report covers submission/replay, all three staff roles, isolation, CSRF, logout, cookies, CSP, API no-store and edge limits. The operations report covers authenticated STARTTLS capture, the routed recipient, backup/restore with the unique index, a retention dry-run/delete limited to one marked synthetic probe, a real API outage/recovery, certificate expiry warning and nginx reload. Example policy values do not install recurring production jobs or external alerts.

Current application checks: 32 backend tests and 22 Flutter tests passed, the analyzer was clean, and release web and signed Android builds passed. The browser rehearsal checks mobile locale screenshots after the language menu closes and landscape search in a short viewport. See the current generated reports for this instance's results; hosted GitHub Actions results remain separate.

Revalidated on 2026-11-18 for frontend 1.3.2/backend 1.2.2: the refreshed containers passed the complete HTTPS/browser/operations rehearsal, including landscape search, routed TLS mail, scoped staff access and backup/restore. Generated reports and images are under `deploy/.synthetic/`; signed native artifacts are under `deploy/.synthetic-android/`.

## Android prototype artifact

With JDK 17, Flutter 3.24.5 and Android SDK build-tools 34.0.0 activated:

```sh
python3 scripts/build-synthetic-android.py --apk
```

This produces a signed AAB and an installable `deploy/.synthetic-android/synthetic-only.apk`, verifies their synthetic signing identity/application ID and records hashes in `report.json`. It uses a separate generated test key and preserves operator signing files. The optional APK can be installed on a test device with `adb install -r deploy/.synthetic-android/synthetic-only.apk` once a device is available.

The profile's native API origin is a replaceable loopback placeholder. A physical device needs a reachable HTTPS backend with a certificate trusted by that device; localhost on a phone refers to the phone itself. Change `native.apiBaseUrl` and rebuild for that setup. Packaging verification does not establish native runtime behavior, and the helper does not weaken native TLS trust.

Validation on 2026-11-17: the refreshed full HTTPS/browser/operations rehearsal passed, including the closed-menu locale captures. The AAB and APK built and passed signing/identity checks. In 1.3.2, Kotlin 1.8.22 paired with Android Gradle Plugin 7.4.2 resolves the Kotlin metadata compatibility diagnostics observed in that earlier build. The SDK 34 compatibility setup does not establish current store eligibility; device execution and current store requirements still need review before distribution.

## Prototype completion versus release handoff

The implemented customer/staff prototype and synthetic deployment are ready for demonstration. Real release work still requires an actual host/domain/database, approved institution mappings and identities, provider credential revocation/delivery, operational policy approval and scheduling, fluent-speaker review, native-device checks, and store identities/accounts. iOS archives require macOS/Xcode. These cannot be established by fictional credentials or Linux packaging.

Use the replacement table in the [synthetic guide](../deploy/synthetic/README.md), the [deployment guide](../deploy/README.md) and [release checklist](RELEASE.md) for that handoff. Generated keys, credentials, backups and data stay out of Git. Do not promote the synthetic database or test signing identity to production.
