# Application structure and behavior

- `models/`: immutable catalogue and inquiry request/receipt types.
- `data/catalogue_repository.dart`: loads the bundled JSON catalogue.
- `services/inquiry_api.dart`: configurable API location, JSON contract, timeout and errors.
- `services/validators.dart`: shared form validation, including safe numeric parsing.
- `l10n/app_strings.dart` and `l10n/translations.dart`: centralized Sinhala/English/Tamil customer messages, locale scope and selector. Original scheme/branch data is separate; staff labels remain English.
- `widgets/app_page.dart`: shared responsive page shell and details card.
- Named category, loan list/detail and inquiry screens replace numbered screen classes.

The form shows a submission state, prevents repeated taps, preserves entered details on failure, and checks widget lifecycle before UI updates. A random submission key is generated with the first validated payload. After an ambiguous network/server failure, fields remain locked and Retry sends exactly that payload and key. A validation rejection unlocks correction; success shows a selectable reference and prevents resubmission. A reference confirms storage, not email delivery or credit approval.

Payload/key retention is in memory for the current form only. Closing/reloading/navigating away loses it. Persistent recovery across sessions is deferred to avoid storing NIC/contact details in browser storage by default. Users should retry on the current form when receipt is uncertain. The backend provides persistent idempotency for any retained key.

The branch chooser is searchable and gender selection no longer uses fixed-width rows. Pages constrain content width on desktop and scroll with the keyboard on narrow devices. A consent checkbox and localized contact notice explain that the inquiry team and, where configured, the responsible financial institution receive details for follow-up.

Both repositories should be deployed together, backend first. V1 requests use canonical names and catalogue IDs; the frontend requires a structured `received` receipt and will not interpret an arbitrary HTTP 200/error body as success. The backend retains a legacy adapter for old clients.

Deferred: current scheme verification, public status lookup, verified eligibility assessment, approved catalogue translations and reduced initial identity collection. Search/comparison, inquiry-preparation guidance and customer interface locales are implemented in 1.3. Institution routing and an internal officer inbox are implemented in 1.2. No automated financial assessment has been added.

## Staff portal in 1.2

`staff/` contains typed staff models, a credentialed web HTTP client, portal/filter screens and inquiry detail updates. The public form retains its existing API contract. The staff API shares the configured base URL, keeps its CSRF value in memory and relies on browser-managed HttpOnly cookies. The web-only entry does not add native staff-session support. See docs/STAFF.md for deployment and workflow limits.

## Discovery in 1.3

`services/loan_discovery.dart` implements deterministic text/purpose filtering and a bounded comparison selection. `loan_options_screen.dart` keeps search, filters and selected IDs in screen memory; comparison resolves selections against the full catalogue so filtering does not silently remove them. The comparison table retains original strings. `guidance_screen.dart` uses purpose for navigation and business stage for preparation tips only. See docs/DISCOVERY.md for supported behavior and missing real-world eligibility data.
