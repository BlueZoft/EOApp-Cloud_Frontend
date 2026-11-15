# Changelog

## 1.1.0+2 — 2026-11-15

- Replaced numbered screens with named catalogue and inquiry screens.
- Added immutable models, a separate API service, shared validation and page widgets.
- Extracted the unchanged 15 schemes and 276 branches into bundled JSON with stable IDs.
- Added configurable HTTPS API location, typed receipts, timeout and visible errors.
- Added submission state and duplicate prevention; ambiguous retries reuse payload/key.
- Added contact consent, searchable branch selection and responsive form layout.
- Fixed welcome-image registration, Android Internet permission and web bootstrap metadata.
- Bundled CanvasKit renderer configuration and licensed fonts to avoid runtime CDN dependencies.
- Centralized Sinhala inquiry copy and documented configuration/upgrade behavior.

Validation: Flutter 3.24.5 / Dart 3.5.4; analyzer clean, six tests passed, release web build passed. A Chromium smoke check traversed welcome → category → agriculture catalogue with no page errors or failed requests. Android/iOS packaging and external SMTP delivery were not tested. Current scheme verification, additional languages, officer workflows and institution routing remain deferred.
