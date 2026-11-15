# Search, comparison and customer languages — 1.3

## Discover schemes

The category screen now provides **Search all schemes** and **Help me explore**, as well as the existing purpose categories and general inquiry.

Search runs locally over scheme names, descriptions, intended beneficiaries, listed activities, rates, limits and repayment text. It is case-insensitive, trims whitespace and requires every query word to appear somewhere in the indexed text. The purpose filter combines with the search. Category names in Sinhala, English and Tamil are also indexed, so a translated purpose term can find its category even though the original scheme descriptions remain in Sinhala. This does not translate arbitrary activity descriptions or add institution/geography/amount filters.

Search preserves catalogue ordering. It does not rank approval likelihood, interpret interest-rate formulas or convert free-form limits to numeric eligibility rules. No customer data or search history is sent to a server or persisted by this feature.

## Compare two or three schemes

Select up to three schemes; select at least two to open comparison. Selected schemes remain in the visible selection strip when search or purpose filters hide their cards. Remove them with the chip's remove action. Selection is in memory for the current search screen and is cleared when that screen is disposed.

The comparison table shows the **original** audience, maximum amount, interest rate, repayment period and eligible-activity text. Horizontal scrolling makes the table usable on narrow screens. A details action leads to the existing inquiry flow for each scheme. Variable, conditional or ambiguous values are displayed verbatim; the app does not choose a lowest rate, calculate repayment, or promise eligibility.

## Guided inquiry preparation

The guide asks for a purpose and an optional business stage. Purpose selects the matching catalogue category (or all categories if unsure). Stage changes practical preparation tips: describe a new idea, an existing activity or make a general inquiry when unsure. Stage does **not** exclude schemes, assign a suitability score or change credit terms. Answers remain on that screen and are not silently submitted with an inquiry.

A stronger eligibility/matching feature requires reviewed institution rules that the current catalogue does not supply:

| Missing real-world input | Needed before using it as an eligibility rule |
| --- | --- |
| Institution-approved scheme ownership | Confirm which institution actually offers each scheme |
| Numeric amounts/rate types/fees | Verified units, ranges, conditions and effective dates |
| Geographic and branch coverage | Approved service areas and branch relationships |
| Business-stage and applicant requirements | Explicit criteria, exceptions and required evidence |
| Product availability and source | Named owner, official source and last verification date |

Until supplied and reviewed, those fields must not be inferred from an old description. Present-day catalogue verification remains deferred by request.

## Customer languages

The welcome screen and shared page header offer Sinhala, English and Tamil. Customer navigation, guide/search/comparison controls, form labels, validation, consent, errors and receipt messages use centralized resources in `lib/l10n/translations.dart`. Language changes preserve active form inputs and comparison selection. The language choice lasts for the current app session; no browser storage is used.

The localized contact notice describes sharing with the inquiry team and, where configured, the responsible financial institution.

The **scheme/branch content stays in its original Sinhala**, with a visible notice in the other interface languages. Staff portal labels remain English. No official translation of financial terms or change to the scheme data is claimed. Have fluent Sinhala/Tamil reviewers check the interface wording and supply approved catalogue translations before a fully translated public release. Keep the same resource keys across locales; tests check parity.

Noto Sans Sinhala, Noto Sans Tamil and Roboto are bundled under their included SIL Open Font Licenses. The theme selects a suitable interface font and falls back to the others for mixed-script catalogue content. Renderer/fonts do not require a runtime CDN.

## Validation and deployment

No backend API or database migration is required. The backend's existing catalogue IDs and inquiry contract are unchanged. Ship the entire new `build/web` directory, including fonts and CanvasKit. Use the existing API-base configuration for inquiry/staff calls.

Tests cover multi-word/category search, translated purpose indexing, selection limits and hidden selections, narrow-screen comparison scrolling, locale key parity, language changes retaining form values/validation, and guide navigation/tips. Existing customer/staff tests remain part of CI. Production SMTP, actual institution mappings, signing identities and other deployment inputs are still configured using the prior release guides.
