# Hetarata / Entrepreneur Outreach frontend — 1.1

Flutter Sinhala credit catalogue and inquiry form. Users choose a funding category, browse 15 retained schemes, inspect terms, and submit a scheme-specific or general inquiry to the Express API. Loan rates/text and branch names are unchanged; this release does not verify their present availability.

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

Tests cover validators, API error contracts, timeout handling, retry keys, receipt parsing, narrow-screen form layout and submission state. No test sends real email. Validate a production build against its intended HTTPS backend before release; a local web build alone does not verify deployment routing, real SMTP or Android/iOS packaging.

Web builds load their bundled CanvasKit renderer and Noto Sans Sinhala font locally, avoiding renderer/font CDN dependencies. Bundled fonts: Noto Sans Sinhala ([license](assets/fonts/OFL.txt)) and Roboto ([license](assets/fonts/Roboto-OFL.txt)), obtained from the Google Fonts repository under the SIL Open Font License. Distribute the entire `build/web` output, including `canvaskit/` and `assets/`.

## Real-world configuration placeholders

Copy `config/production.example.json` to ignored `config/production.json` and replace the example API hostname with your HTTPS backend. Build using `flutter build web --dart-define-from-file=config/production.json`. This file is public build configuration: never put credentials in it. Backend SMTP values belong only in secure backend configuration.

Native store releases also need your actual Android application ID/iOS bundle ID, store display name, signing identity/keystore, and store accounts. The existing `com.example.flutter_frontend` identifier and debug signing setup are development placeholders, not production release credentials. iOS archive validation requires macOS/Xcode and cannot run in this Linux cloud environment.
