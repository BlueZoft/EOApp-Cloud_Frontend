# Version 1.1 structure and behavior

- `models/`: immutable catalogue and inquiry request/receipt types.
- `data/catalogue_repository.dart`: loads the bundled JSON catalogue.
- `services/inquiry_api.dart`: configurable API location, JSON contract, timeout and errors.
- `services/validators.dart`: shared form validation, including safe numeric parsing.
- `l10n/si.dart`: centralized Sinhala inquiry messages; other screens still have Sinhala labels. No additional language support is claimed.
- `widgets/app_page.dart`: shared responsive page shell and details card.
- Named category, loan list/detail and inquiry screens replace numbered screen classes.

The form shows a submission state, prevents repeated taps, preserves entered details on failure, and checks widget lifecycle before UI updates. A random submission key is generated with the first validated payload. After an ambiguous network/server failure, fields remain locked and Retry sends exactly that payload and key. A validation rejection unlocks correction; success shows a selectable reference and prevents resubmission. A reference confirms storage, not email delivery or credit approval.

Payload/key retention is in memory for the current form only. Closing/reloading/navigating away loses it. Persistent recovery across sessions is deferred to avoid storing NIC/contact details in browser storage by default. Users should retry on the current form when receipt is uncertain. The backend provides persistent idempotency for any retained key.

The branch chooser is searchable and gender selection no longer uses fixed-width rows. Pages constrain content width on desktop and scroll with the keyboard on narrow devices. A consent checkbox explains that the application's inquiry team receives contact details; no institution-specific routing is implied.

Both repositories should be deployed together, backend first. V1 requests use canonical names and catalogue IDs; the frontend requires a structured `received` receipt and will not interpret an arbitrary HTTP 200/error body as success. The backend retains a legacy adapter for old clients.

Deferred: current scheme verification, institution/branch routing, officer dashboard and status lookup, comparison, eligibility guidance, Tamil/English translations and reduced initial identity collection. No automated financial assessment has been added.
