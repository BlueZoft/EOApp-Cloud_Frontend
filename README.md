# Hetarata / Entrepreneur Outreach frontend — 1.3.2

Start with the [prototype walkthrough and handoff](docs/PROTOTYPE.md) for the completed customer/staff flows, synthetic demonstration, generated evidence and Android prototype artifact.

Version 1.3.2 fixes staff response parsing and expired-session handling, removes details after inquiry access is withdrawn, and makes search usable in short landscape/keyboard viewports. Android packaging now uses the compatible Kotlin 1.8.22 / Android Gradle Plugin 7.4.2 pair. The matching backend 1.2.2 fixes credential-reset races, stale delivery-worker updates and combined reference/cursor filtering.

Flutter credit catalogue and inquiry form with a Sinhala/English/Tamil customer interface. Users search/filter the 15 retained schemes, compare two or three, inspect terms, and submit a scheme-specific or general inquiry to the Express API. Loan rates/text and branch names are unchanged; this release does not verify their present availability.

## Develop and build

Use Flutter 3.24.5 (Dart 3.5.4), the toolchain validated for this release. Later SDK upgrades should update the lockfile and rerun checks deliberately. On managed machines with a read-only home, set `PUB_CACHE=/workspace/.cache/pub` and `XDG_CONFIG_HOME=/workspace/.cache/config` so SDK/package configuration uses writable directories.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=API_BASE_URL=http://localhost:5000
```

Start the backend separately using its README. Allow `http://localhost:8080` in backend `CORS_ORIGINS`. The URL above is for a browser on the development machine. For deployed builds use HTTPS:

```sh
flutter build web --dart-define=API_BASE_URL=https://api.example.org
```

`API_BASE_URL` is the API host/base path, **without** `/api/v1/inquiries`. It is compile-time public configuration, never a credential. Without a value, web builds call `/api/v1/inquiries` on their own origin; configure the hosting reverse proxy accordingly. Native builds require an explicit URL. Insecure HTTP is accepted only in debug mode for localhost, 127.0.0.1 or Android emulator host 10.0.2.2. Release builds require HTTPS. Android release Internet permission is included; this change does not weaken platform cleartext policies.

See [architecture and release notes](docs/ARCHITECTURE.md) for API changes, duplicate handling and remaining limitations.

## Catalogue maintenance

`assets/catalogue.json` separates retained content from widgets. Its copy must match the backend's `data/catalogue.json`. IDs are stable identifiers, not list positions to be regenerated. Preserve IDs when reordering entries. `general` identifies an inquiry without a selected scheme. The welcome image is registered as `assets/fscreen.jpg`.

## Checks

Tests cover discovery/comparison, customer locales, validators, API contracts, timeouts/retry keys, receipt parsing, staff access flows and narrow-screen layouts. No test sends real email. Validate a production build against its intended HTTPS backend before release; a local web build alone does not verify deployment routing, real SMTP or Android/iOS packaging.

Web builds load their bundled CanvasKit renderer and Noto Sans Sinhala/Tamil fonts locally, avoiding renderer/font CDN dependencies. Bundled fonts: Noto Sans Sinhala ([license](assets/fonts/OFL.txt)), Noto Sans Tamil ([license](assets/fonts/NotoSansTamil-OFL.txt)) and Roboto ([license](assets/fonts/Roboto-OFL.txt)), obtained from the Google Fonts repository under the SIL Open Font License. Distribute the entire `build/web` output, including `canvaskit/` and `assets/`.

## Real-world configuration placeholders

Copy `config/production.example.json` to ignored `config/production.json` and replace the example API hostname with your HTTPS backend. Build using `flutter build web --dart-define-from-file=config/production.json`. This file is public build configuration: never put credentials in it. Backend SMTP values belong only in secure backend configuration.

Native store releases also need your actual Android application ID/iOS bundle ID, store display name, signing identity/keystore, and store accounts. The existing `com.example.flutter_frontend` identifier is for development. Release builds require filled, ignored signing properties and do not fall back to debug signing. iOS archive validation requires macOS/Xcode and cannot run in this Linux cloud environment.

See [release checklist](docs/RELEASE.md) for Android/iOS identity and signing placeholders, debug networking, toolchain requirements and CI coverage.

## Officer inbox

The web welcome screen includes an opt-in, authenticated staff workflow for institutional follow-up. See [staff portal guide](docs/STAFF.md) and the backend provisioning instructions. No default login or institution associations are shipped. Customer catalogue content is unchanged; the staff portal currently uses English labels.

## Search, comparison and language support

See [discovery and language guide](docs/DISCOVERY.md). Customer interface text is available in Sinhala, English and Tamil; original scheme/branch content remains Sinhala and staff screens remain English. Search and purpose filtering are local. The preparation guide helps frame an inquiry and does not assess eligibility. Comparison preserves conditional rates/limits exactly as listed. Native-speaker review and approved translations of financial content remain real-world review inputs.

## Docker-host HTTPS deployment

See [Docker host guide](deploy/README.md) for a private API behind a non-root HTTPS proxy, configuration/TLS placeholders, same-origin builds, operator provisioning and a disposable full-stack rehearsal. `scripts/build-web-deploy.sh` produces the Docker bundle and public build metadata. No production database, certificate or staff identity is created automatically.

The [synthetic release guide](deploy/synthetic/README.md) supplies replaceable fictional institutions/staff/applicants, local TLS email capture, an inspectable loopback stack, operations reports and a locally signed Android rehearsal bundle. All generated credentials, data and keys are ignored. It documents exactly how to replace each input for a real release and which provider/device/human checks remain external.
