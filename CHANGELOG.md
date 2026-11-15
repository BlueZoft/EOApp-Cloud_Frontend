# Changelog

## 1.3.0+4 — 2026-11-15

- Added local multi-word scheme search and purpose filters, including translated category-name indexing.
- Added two/three-scheme comparison with selections retained across filtering, original conditional terms and horizontal scrolling on narrow screens.
- Added guided inquiry preparation: purpose selects a category and business stage changes preparation tips. No eligibility/affordability decision is made.
- Added Sinhala/English/Tamil customer interface resources, a session language selector, localized form validation/consent/receipts and bundled Noto Sans Tamil font.
- Preserved the original scheme/branch catalogue. Other interface languages explain the Sinhala content fallback; staff labels remain English.
- Updated the contact notice to describe the existing responsible-institution routing, and documented translation review and missing verified eligibility inputs.

Validation: 17 frontend tests passed, analyzer clean, release web and Android debug APK builds passed. Browser search → select two schemes → compare → switch to Tamil passed with no page errors/failed requests; narrow-screen mixed-script rendering was inspected. Catalogue text is unchanged and still matches the backend copy. Production SMTP/HTTPS configuration, approved mappings, fluent-speaker/catalogue translation review and signed store releases remain external inputs.

## 1.2.0+3 — 2026-11-15

- Added a web officer portal with sign-in/session restoration/sign-out, status/reference filters, pagination and inquiry contact details.
- Officers see their institution's inquiries; administrators can review unassigned inquiries and assign institutions. Status edits send an expected version and CSRF token.
- Added a credentialed browser client using browser-managed HttpOnly cookies; no session token/password is stored in browser storage or build configuration.
- Added explicit accessible inquiry-row actions and handling for inactive institution filters. The customer catalogue remains unchanged; staff labels are currently English.
- Added staff setup/deployment documentation and tests for officer/admin flows, optimistic conflicts, filters and expired sessions.

Validation: 11 frontend tests passed; analyzer clean, release web build and Android debug APK packaging passed. A browser check verified sign-in, same-site cross-origin credentials, scoped inquiry details and logout against a live local API. Production HTTPS deployment, real institution accounts and signed store releases still require the documented real-world configuration. Native staff sessions are not included.

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

### Follow-up validation and release preparation

- Added GitHub Actions for analyzer/tests/web build and JDK 17 Android debug packaging.
- Android debug APK builds successfully. Missing real signing/identity configuration causes an explicit release-task failure instead of debug-key signing.
- Added ignored Android signing-property templates, debug-only local networking and documented production/native identity requirements.
- iOS signing/archive checks still require macOS/Xcode and an authorized Apple Developer identity; no store release is claimed.
