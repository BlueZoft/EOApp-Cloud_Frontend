# Native and web release preparation

## Configuration placeholders

| Value | Where to supply it | Current status |
| --- | --- | --- |
| Actual HTTPS API base URL | Copy `config/production.example.json` to ignored `config/production.json` | Placeholder; replace before deployment |
| Android application ID | `applicationId` in ignored `android/key.properties` | Development ID until supplied |
| Android signing identity | `storeFile`, `storePassword`, `keyAlias`, `keyPassword` in the same ignored file | Not supplied |
| iOS bundle ID and signing team | Xcode Runner target signing settings | Needs your Apple Developer configuration |
| Store identity, icons, privacy/support URLs | Store consoles and app metadata | Needs product-owner information |
| Inquiry recipient, SMTP and database credentials | Backend secure configuration only | See backend release checklist |

No SMTP credential belongs in a Flutter configuration file: all Flutter build values are public. Keystores, filled signing properties and local deployment JSON are ignored by Git.

## Web

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/production.json
```

Deploy the entire `build/web` directory. An omitted API base URL requires an HTTPS same-origin reverse proxy for `/api/v1/inquiries`. Verify a real submission against your deployed API and approved test mailbox before public release. The web renderer and fonts are bundled locally.

## Android

Use JDK 17 with Gradle 7.6.3, Android Gradle Plugin 7.4.2 and Kotlin 1.8.22, Android SDK platform 34 and build-tools 30.0.3/34.0.0, and Flutter 3.24.5. This plugin pairing resolves the earlier Kotlin metadata compatibility diagnostics. Do not use JDK 21 with this Gradle version. `JAVA_HOME` must point to your JDK 17 installation; `ANDROID_HOME` must point to the SDK. Retain package checksums, trusted CA configuration and TLS verification when installing tools.

Development builds use the existing development ID and Android debug signing:

```sh
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Only the debug manifest permits cleartext to localhost/127.0.0.1/10.0.2.2 for local development. Release networking still requires HTTPS. Debug APKs are not store releases.

For a store release, copy `android/key.properties.example` to ignored `android/key.properties`, replace all values and use your own protected keystore. Paths are resolved from the Android directory; an absolute keystore path avoids ambiguity. Release tasks fail explicitly when the identity/signing placeholders are missing; they no longer fall back to debug keys.

```sh
flutter build appbundle --release --dart-define-from-file=config/production.json
```

Keep signing credentials in a secure CI secret store and never commit generated key files. Confirm current store target-SDK and policy requirements before submission: the retained SDK 34 configuration is for compatibility validation and does not establish current Google Play eligibility.

## iOS

Archive validation requires macOS and Xcode; Linux cannot produce or validate a signed iOS archive. On an authorized Mac, configure the actual bundle ID and signing team in Xcode and use:

```sh
flutter build ipa --release --dart-define-from-file=config/production.json
```

Supply App Store metadata, privacy disclosures and provisioning through your Apple Developer account. No signing identity is invented or committed here.

## Continuous integration

`.github/workflows/validate.yml` runs the Flutter analyzer, tests, web build and Android debug packaging without production credentials. Actual hosted run results must be checked for each pushed commit. Native store release jobs remain dependent on the identities, signing assets and platform requirements above.

Local evidence: Android debug APK packaging passed; the missing-signing release guard was verified as an expected failure. Device/emulator execution, signed release bundles and iOS archives remain unverified.

## Staff portal in 1.2

Configure same-origin/same-site HTTPS hosting for the browser-managed staff cookie and enable/provision the backend explicitly. Staff sign-in is web-only; do not put an officer password in native/web build configuration. See [staff portal guide](STAFF.md).

## Customer discovery/languages in 1.3

No new API setting, credential or data migration is required. Review the new Sinhala/English/Tamil interface text with fluent speakers, check mixed-script font rendering and confirm search/comparison on the target devices. Original Sinhala scheme/branch descriptions remain unchanged; approved translations and verified eligibility metadata are still required for those future extensions. See [discovery guide](DISCOVERY.md).

## Docker host preparation

For backend 1.2.2, recreate all API/notification-worker instances together so every worker enforces delivery claim ownership. Existing account/session records remain compatible with revision zero until the next operator reset/disable. The upgrade adds no destructive data migration. Match it with frontend 1.3.2 for the staff/privacy and responsive-layout fixes.

The [Docker-host guide](../deploy/README.md) provides the selected same-origin HTTPS target, a Compose stack, ignored `.env.deploy`/TLS locations and an optional isolated deployment rehearsal. Real credentials/certificates remain host configuration; the normal stack does not create a production database. Keep its API private when using the explicit one-hop proxy trust setting.

Local rehearsal passed on 2026-11-16 with backend 1.2.1: a browser submitted and replayed an inquiry over HTTPS, signed into the provisioned synthetic officer inbox, updated status with CSRF protection and signed out. TLS/redirects, CSP, secure cookies, body/rate limits and private/non-root containers also passed. See the Docker-host guide for the repeatable command and rollout/rollback steps. Production host/SMTP checks still require the real-world values above.

## Synthetic release inputs and signing rehearsal

See [synthetic release guide](../deploy/synthetic/README.md) and `deploy/synthetic/profile.json` for fictional directory/accounts/applicant data, example operating policies and an `org.example.*` native identity. The expanded local runner captures real authenticated STARTTLS delivery without external relay, checks backup/restore and synthetic retention, and writes browser/operations reports and mobile-width locale screenshots. Its optional `--keep` mode retains private local evidence for inspection; it does not configure a public production host.

`python3 scripts/build-synthetic-android.py` generates an ignored, isolated signing identity and verifies the resulting AAB manifest and signature. `EOAPP_SIGNING_PROPERTIES` can select a protected signing-properties path; omitted, the release build still uses `android/key.properties` and its existing missing-placeholder guard. Synthetic artifacts are not store releases. Use the real signing/account/policy requirements above for publication; iOS archiving still requires macOS/Xcode.
