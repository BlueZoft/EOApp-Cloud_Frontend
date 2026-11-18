# Officer inbox — frontend 1.3.2

The web welcome screen has an **Officer inbox** entry for authorized staff. There are no default credentials or public registration. Enable and provision the backend using its `docs/STAFF.md`; real institution mappings, staff identities and approved mailbox addresses are required.

The portal supports sign-in/sign-out, session restoration, status/reference filters, cursor pagination, contact details and status updates. Administrators can filter unassigned cases and change the assigned institution. Officers cannot select another institution or access its inquiries. The backend enforces access independently of the UI.

Staff copy is currently English; customer interface text is available in Sinhala, English and Tamil, while original loan/branch content remains Sinhala. The staff entry is web-only; native applications remain the public customer app.

## Deployment

Use the same `API_BASE_URL` configuration as the public form, or omit it for an HTTPS same-origin reverse proxy. A same-origin frontend/API deployment is preferred. The browser client sends credentials explicitly; Secure/HttpOnly/SameSite=Strict cookies require same-site hosting. Use exact credentialed CORS origins when ports or subdomains differ. For local HTTP, use `localhost` for both sides and the backend's documented development-only cookie configuration. Never put staff passwords or SMTP credentials in Flutter build settings.

Session cookies are managed by the browser, not JavaScript storage. The portal retains CSRF tokens only in memory and restores a session through the API. Sign-out revokes the current server session; account/password changes are operator-administered. Session expiry returns users to sign-in when the inbox reloads. If sign-out cannot reach the server, the UI reports the failure rather than pretending the session was revoked.

HTTP 401 clears local CSRF/session state even if an ingress returns non-JSON content. Malformed successful API payloads become a visible typed error. Backend 1.2.2 binds sessions to credential revisions so operator resets invalidate late in-flight logins as well as existing sessions.

## Updating inquiries

Status changes follow server-defined transitions. Assigning an institution resets status to new. Existing sent notifications are not resent. If delivery is in progress, the server refuses reassignment until the claim completes/recovers. Refresh after a 409 or uncertain timeout before deciding whether to make another change; expected workflow versions prevent overwriting a colleague's update.

Details show contact name, telephone, optional email, selected scheme/branch and inquiry text. NIC/address/age/gender are not fetched by this portal. Recent history records the acting staff member, action and time; the backend retains the latest 100 events. No public status lookup or automated credit approval is introduced.

If a reload/status update returns not-found, forbidden or unauthenticated, previously loaded inquiry details are removed. For example, a reassigned inquiry disappears from the old officer's details view on refresh instead of leaving contact data displayed. Session expiry also clears old inbox filters before the next sign-in.

## Verification

Frontend tests cover CSRF/version propagation, filtered pagination, expired sessions, error responses and a narrow-screen sign-in → inquiry → status-update flow. Backend tests verify authorization, routing and concurrency independently. Production staff access still requires HTTPS deployment, actual provisioned staff and institution mapping review; local tests do not supply those real-world identities.
