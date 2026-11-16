# Docker host with a same-origin HTTPS reverse proxy

This packages the existing Flutter web app and persistent Express API. It does not publish a site or provision a real database, domain, certificate, mailbox or staff identity. The normal stack has **no MongoDB service and no public API/database ports**; point it at your private production MongoDB. The isolated QA runner supplies its own disposable database.

## Files and prerequisites

Keep both repositories checked out together:

```text
parent/
  EOApp-Cloud_Frontend/
  EOApp-Cloud_Backend/
```

Use Docker Engine/Compose v2, the documented Flutter 3.24.5 SDK, and the backend's supported Node runtime inside its image. `BACKEND_CONTEXT` can be an absolute path when checkouts differ. Build contexts and TLS paths resolve relative to `deploy/compose.yaml`, not the shell's current directory.

- `Dockerfile`: serves an already-built web bundle as non-root nginx UID 101.
- `compose.yaml`: private API plus HTTPS edge; no production database is created.
- `.env.deploy.example` in the frontend root: deliberately unusable real-world placeholders.
- `qa/`: optional, local-only integration rehearsal using temporary certificates and synthetic data.

## Build a release bundle

From the frontend root, use a clean, reviewed checkout of both repositories:

```sh
flutter pub get --enforce-lockfile
./scripts/build-web-deploy.sh
```

Set `FLUTTER_BIN=/absolute/path/to/flutter` if necessary. The script builds **without** an external `API_BASE_URL` and writes public `build/web/deployment.json` metadata: app version, source commit, dirty-working-tree flag and same-origin API mode. It contains no credentials. The web image requires this marker and a built JavaScript bundle. For a production release, rebuild from a clean tree so `dirty` is false.

The browser calls `/api/v1/...` through the edge. Do not reuse a bundle compiled for an unrelated API host: the shipped Content Security Policy permits same-origin connections. Separate-origin hosting is a different deployment configuration.

## Supply real configuration securely

```sh
cp .env.deploy.example .env.deploy
chmod 600 .env.deploy
```

Edit the ignored file or inject the equivalent runtime values through your host's secret management. Do not paste secrets into chat, Git, Docker build arguments or frontend build settings. Values containing `$`, `#` or whitespace must be quoted correctly for Compose's env-file syntax; single quotes prevent interpolation of literal secret values.

| Setting | Real-world value to supply |
| --- | --- |
| `SERVER_NAME` | One lowercase DNS hostname, without scheme/path/port |
| `PUBLIC_ORIGIN` | Matching HTTPS origin; omit a trailing slash and the default `:443` |
| `MONGO_URI` | Private database URI/credentials with the required application/index permissions |
| `TLS_CERT_DIR` | Directory containing regular `fullchain.pem` and `privkey.pem` files |
| `TLS_READ_GID` | Container-visible group allowed to read the mounted certificate directory/key |
| `HTTP_BIND`, `HTTPS_BIND` | Explicit host bind addresses/ports; defaults bind loopback only |
| `SMTP_*` | Approved provider, rotated password, sender and authorized recipient; leave disabled until ready |
| `STAFF_ENABLED` | Enable only after provisioning actual institutions and named staff |
| `RELEASE_TAG` | An operator-chosen image tag identifying this rollout |

On a public host, bindings are commonly `0.0.0.0:80` and `0.0.0.0:443`; choose them deliberately with your host firewall and DNS. No public binding is selected automatically. API container port 5000 remains private.

## TLS files and renewal

Certificate issuance/renewal needs your actual DNS/provider setup. This stack does not invent a domain or install a public certificate issuer. Use a trusted certificate and its complete chain for the real hostname. Prefer DNS-based issuance or an existing certificate manager; an HTTP-01 webroot handler is not included.

Keep private keys non-world-readable. A typical mounted directory is mode `0750` with key/chain files `0640`, owned by the deployment operator and a controlled read group. Ensure directory traversal for that group is explicitly set even under a restrictive umask. Avoid symlinks whose targets escape the mounted directory; securely stage regular files from your certificate manager instead.

The nginx process is UID 101. `TLS_READ_GID` adds one read group to that container. Rootless engines can present ownership differently, so check the mounted file's numeric group inside a container and set the value accordingly. Do not solve a mount failure with `chmod 644` on a real private key.

After replacing a certificate/key pair through your secure renewal procedure:

```sh
docker compose --env-file .env.deploy -f deploy/compose.yaml exec -T web nginx -t
docker compose --env-file .env.deploy -f deploy/compose.yaml exec -T web nginx -s reload
```

Reload only after the configuration/certificate check succeeds. Configure certificate expiry monitoring and renewal ownership for the actual host. The HSTS policy initially covers this hostname for one day, without `includeSubDomains`; review a longer policy after HTTPS operation is established.

## Start and inspect

```sh
docker compose --env-file .env.deploy -f deploy/compose.yaml config --quiet
docker compose --env-file .env.deploy -f deploy/compose.yaml build
docker compose --env-file .env.deploy -f deploy/compose.yaml up -d --no-build --wait --wait-timeout 180
docker compose --env-file .env.deploy -f deploy/compose.yaml ps
```

`config --quiet` validates without printing interpolated secrets. Do not share full `docker inspect` or expanded Compose configuration output: runtime environments can contain credentials. For a proxy requiring a corporate CA, prebuild the API image using its documented BuildKit secret and the same `eoapp-api:<RELEASE_TAG>` tag; never disable TLS verification. Resolve the configured proxy hostname inside build containers using your engine's supported DNS/host mapping.

The edge redirects HTTP to the configured HTTPS origin. `/api/ready` checks API/database readiness; `/deployment.json` identifies the served web build. Web container health checks the local nginx process separately. The browser headers restrict framing, sniffing and cross-origin resources. Request bodies over 16 KiB and edge rate limits return JSON errors. Operational access logs omit queries, cookies, authorization headers and request bodies; log rotation is bounded in Compose.

The API explicitly trusts **one** proxy hop in this stack, and nginx overwrites forwarding headers with its observed client address. Keep the API private. Do not expose its port or reuse the one-hop setting on an arbitrary network path: bypassing the edge would allow forwarded-address spoofing. Direct API deployments retain the default `TRUST_PROXY_HOPS=0`. An additional CDN/load balancer requires a reviewed forwarding/trust configuration.

The API and edge run non-root with read-only root filesystems, dropped capabilities and bounded temporary filesystems. Their normal outbound access must still reach your private database/SMTP service as required. There is no zero-downtime guarantee for this single-host/single-API stack; choose a maintenance window and rollback plan for updates.

## Rollout and rollback

Record both repository commit IDs, the chosen `RELEASE_TAG`, the built image IDs/digests and a protected copy of the host configuration before rollout. Use unique release tags and retain the previous API/web image pair. Back up the private MongoDB database using your approved procedure and verify that the backup can be restored before a production upgrade.

After startup, check `https://YOUR_HOST/api/ready` and `https://YOUR_HOST/deployment.json` with normal certificate verification. Confirm the expected web source commit and `dirty: false`, then use an approved test identity to check inquiry receipt/replay, the provisioned officer's scoped inbox, a status change and logout. If SMTP is enabled, independently confirm delivery to the approved test mailbox. The local synthetic rehearsal does not replace this host-specific check.

If verification fails, restore the previous protected runtime configuration and set `RELEASE_TAG` to the retained previous image pair. Run the same `up -d --no-build --wait` command and repeat readiness and browser checks. Do not rebuild over the old release tag. This deployment adds no data migration; rolling back images does not roll back inquiries or notification state. Restore data only through the agreed incident/backup procedure. Never remove production data volumes as part of a code rollback.

## Provision institutions and staff

Read the backend's `docs/STAFF.md`. Directory JSON can be streamed without copying operational files into the image:

```sh
cat config/institutions.json | docker compose --env-file .env.deploy -f deploy/compose.yaml exec -T api node scripts/staff.js import-directory --file /dev/stdin
docker compose --env-file .env.deploy -f deploy/compose.yaml exec api node scripts/staff.js provision --email REPLACE_WITH_ADMIN_EMAIL --name "REPLACE_WITH_ADMIN_NAME" --role admin
```

The directory file belongs to the operator and uses the backend's template/schema. The staff command prompts for a hidden password; do not put it in arguments. Keep `STAFF_ENABLED=false` until mappings/accounts are ready, then update the runtime environment and recreate the API. There are no default accounts, no inferred institution relationships and no automated backfill.

Enable SMTP only after rotating the historical password and configuring an approved sender/recipient. Confirm real delivery using an authorized test mailbox. Disabled historical notifications are not automatically requeued. Database backups, personal-data access/retention rules and alert destinations remain operator decisions; the QA runner does not supply them.

## Optional disposable HTTPS rehearsal

This does not use `.env.deploy` or production data. It forces a synthetic MongoDB URI, disabled SMTP, temporary TLS files, generated test credentials and a UUID project name; cleanup removes only that project's containers, volume and network. Run it on the local Docker host with both repositories present.

```sh
npm ci --prefix deploy/qa
cd deploy/qa && npx playwright install chromium && cd ../..
python3 deploy/qa/run.py
```

Python 3, Node 22+, OpenSSL, Docker and an installed Chromium are needed only for this optional test. `CHROMIUM_EXECUTABLE=/path/to/chromium` selects an existing browser. `--docker-host` selects the same engine used for builds. If images were prebuilt with environment-specific trust settings, use `--no-build --release-tag deploy-validation` with `eoapp-api:deploy-validation` and `eoapp-web:deploy-validation`.

The rehearsal verifies real TLS chain/hostname checking, HTTP redirect, static/API error behavior, public submission/replay, Secure/HttpOnly/Strict staff cookies, CSRF-protected updates, logout, CSP, body limits, rate limits and private/non-root containers. Chromium trusts only the generated local test certificate's pinned public key; Python/Node separately validate its full CA chain and hostname. The helper refuses non-loopback targets and never uses a global `ignoreHTTPSErrors` setting. Production browsers use normal certificate trust with no test flags.

This is local evidence, not a production deployment or real-provider test. Android device/emulator execution, macOS/iOS archives, actual SMTP/DNS/HTTPS ingress, translation review, verified catalogue rules and store identities remain separate prerequisites. Never use `down --volumes` on a production data stack; only this disposable runner creates/removes its own test database volume.

### Recorded local validation — 2026-11-16

With the matching backend 1.2.1 image and same-origin frontend 1.3 bundle, this command passed using prebuilt images on the managed Docker host:

```sh
CHROMIUM_EXECUTABLE=/usr/bin/chromium python3 deploy/qa/run.py \
  --no-build --release-tag deploy-validation \
  --docker-host unix:///var/run/docker.sock
```

Both the browser workflow and the complete stack check reported `PASS`, and the runner removed its test containers, network and database volume. All 28 backend tests and 17 Flutter tests also passed; Flutter analysis found no issues, the release web bundle/image built successfully, and the backend production/QA dependency audits reported zero known vulnerabilities. This validates the local deployment configuration; real domain/certificate issuance, private production MongoDB, SMTP delivery and approved operational identities remain owner-supplied configuration.
