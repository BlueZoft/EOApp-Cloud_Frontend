# Synthetic deployment and release rehearsal

This profile supplies **fictional institutions, applicants, staff, email destinations, operating policies and a native identity**. It runs on loopback with a private MongoDB and an authenticated STARTTLS mail capture service. Capture never relays email or contacts recipients. Numeric NIC/telephone values are format-valid test inputs, not approved contact identities; never call or message them. The original financial catalogue remains unchanged and unverified for current availability.

## Run or retain the local deployment

Use the sibling frontend/backend checkouts, Docker Compose v2, Flutter 3.24.5, Python 3, Node 22–24, OpenSSL and Chromium. From the frontend root:

```sh
flutter pub get --enforce-lockfile
./scripts/build-web-deploy.sh
npm ci --prefix deploy/qa
python3 deploy/qa/run.py --keep
```

Install Chromium with `cd deploy/qa && npx playwright install chromium` when no browser is installed. Otherwise set `CHROMIUM_EXECUTABLE=/path/to/chromium`. The runner builds the API, web and synthetic mail images unless `--no-build` is supplied. Intercepting proxies may require prebuilding with the documented temporary CA secret and a runtime-resolved host mapping; preserve TLS verification. Use the same Docker engine endpoint for builds and the runner. On the managed host the verified command is:

```sh
CHROMIUM_EXECUTABLE=/usr/bin/chromium python3 deploy/qa/run.py --keep \
  --no-build --release-tag deploy-validation \
  --docker-host unix:///var/run/docker.sock
```

That command expects `eoapp-api:deploy-validation`, `eoapp-web:deploy-validation` and `eoapp-synthetic-mail:deploy-validation`. To prebuild the third image normally:

```sh
docker build -t eoapp-synthetic-mail:deploy-validation deploy/synthetic/mail
```

Successful `--keep` leaves an inspectable stack and ignored `deploy/.synthetic/` state. Without `--keep`, all generated state and test containers/volumes are removed. A failed run removes its containers; retained failure files can be removed with the same stop command below before retrying. An existing state directory is never silently overwritten.

The only host bindings are randomly selected loopback HTTP/HTTPS ports. Read the origin and randomly generated staff passwords locally in `deploy/.synthetic/credentials.json`; do not paste that file into issues/chat. No default password is committed. Use the generated CA only in a disposable test client/profile; public browsers will not trust it. The automated browser pins only this test leaf key, while Python/Node verify the certificate chain and hostname. Certificates last one day: stop/recreate this demo to renew them. Runtime CA overrides exist only in this synthetic Compose overlay.

```sh
python3 deploy/qa/run.py --stop
```

Stop removes only the UUID-named owned demo project, its synthetic data volume and private local state. It does not touch `eoapp-mongo`, production databases or normal `.env.deploy`. Processes must be restarted after a cloud workspace restore; prepared files alone do not establish service readiness.

## Replaceable synthetic inputs and generated evidence

Edit `deploy/synthetic/profile.json`, or pass `--profile /path/to/synthetic-profile.json`. The validator deliberately accepts only `@demo.test` mailboxes and a marked synthetic profile. Keep the first staff account as the officer receiving general inquiries; the browser currently exercises a female general-inquiry applicant and an existing catalogue branch ID. Supply at least two synthetic institutions and an administrator. Changing fixtures never changes the shipped catalogue or configures a real deployment.

| Profile section | Purpose | Replace for a real release |
| --- | --- | --- |
| `directory` | Two fictional teams and explicit scheme mappings | Approved directory via backend `config/institutions.json` and staff import command |
| `staff` | Two scoped officers and an administrator; random passwords generated locally | Named approved staff provisioned securely against the actual database |
| `applicant` | Browser form input; deliberately fictional | Approved test identity for the intended host; never treat demo numeric fields as real contacts |
| `operations` | Example owner, 7-day test retention, 24-hour backup target and local alert destination | Approved owner/access/retention/backup schedule and actual monitoring destinations |
| `native` | `org.example.eoapp.synthetic`, loopback HTTPS base | Real identifiers, API origin and operator-owned signing/provisioning |
| `store-listing.example.json` | Fictional support/privacy/listing fields | Approved store metadata, published privacy policy and current store disclosures |

Generated `browser-report.json` records the inquiry reference and checked browser behavior. Three `welcome-*-mobile.png` screenshots show Sinhala/English/Tamil at 390×844. They establish rendering evidence, not native-device execution or native-speaker approval. Use the images and `docs/DISCOVERY.md` for fluent-speaker review.

`operations-report.json` records authenticated STARTTLS capture and routed recipient, durable notification state, backup hash/restore verification, restored unique index, a retention dry-run/delete against one marked synthetic probe, a real API stop/restart alert/recovery, expiry warning and nginx configuration/reload checks. `synthetic-backup.archive.gz` is mode 0600 and includes synthetic staff password hashes/session data; protect it like a backup. Restore verification uses a second disposable database and removes it afterwards.

The operating policy values are examples. The rehearsal does **not** install a scheduled backup, recurring retention task, external alert delivery or a production monitoring agent. It exercises those operations locally; install schedules/monitoring only after the real owner approves their policy and destinations. Mail capture is in memory and intentionally lost on capture-container restart. No real provider-delivery claim is made.

## Synthetic Android signing and store preparation

Set `JAVA_HOME` to JDK 17, `ANDROID_HOME` to the Android SDK and activate Flutter as described in `docs/RELEASE.md`. Then:

```sh
python3 scripts/build-synthetic-android.py
```

Add `--apk` to also produce an installable `synthetic-only.apk`. This requires build-tools 34.0.0 and verifies its signature and application ID. See [prototype handoff](../../docs/PROTOTYPE.md) for device networking and installation instructions. Device execution still needs a connected device/emulator.

`FLUTTER_BIN=/absolute/path/to/flutter` is supported. The helper generates a 30-day self-signed key and `key.properties` only under ignored `deploy/.synthetic-android/`. It builds an AAB using `EOAPP_SIGNING_PROPERTIES` to select that file, checks the actual bundle manifest's synthetic application ID, verifies its signature and certificate subject, and writes `synthetic-only.aab` plus `report.json` with a SHA256. Existing operator `android/key.properties` is never replaced. Repeated runs reuse the local synthetic key. To choose a different synthetic identity, archive/remove only this generated directory first.

This signed artifact is for packaging rehearsal, not public distribution. It does not add native trust for the local test CA, run on a device, satisfy current store target-SDK rules, or establish production signing. Actual Android releases should use the existing ignored operator signing file (or a secure `EOAPP_SIGNING_PROPERTIES` path) and approved API configuration. Never upload the synthetic key, identity or fictional privacy policy to a store. CI uploads only the synthetic AAB/report, never private signing material.

iOS still needs an authorized macOS/Xcode machine and Apple signing/provisioning. Use the synthetic listing as a replaceable draft, then follow `docs/RELEASE.md` with actual organization values. A Linux build or fabricated account cannot validate an iOS archive or publish either store release.

## Release handoff

For a real host, follow `deploy/README.md` using ignored `.env.deploy`, real TLS/MongoDB/SMTP values and the approved directory. Do not promote this demo database, mail image, CA trust, synthetic key or operating policy to production. Revoke the historical SMTP password in the provider account; synthetic credentials cannot revoke it.

GitHub API access from this environment returned `Forbidden` when checking Actions. Local results are recorded separately; inspect the pushed commit's Actions checks through GitHub before release. This guide intentionally distinguishes completed local synthetic checks from external provider/store actions and human translation review.
