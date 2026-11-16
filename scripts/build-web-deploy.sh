#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Run flutter pub get --enforce-lockfile first. Never pass secrets or an external
# API_BASE_URL: this Docker stack serves /api on the same HTTPS origin.
"${FLUTTER_BIN:-flutter}" build web --no-pub
deployment_version=$(sed -n 's/^version: *//p' pubspec.yaml)
deployment_revision=$(git rev-parse HEAD)
deployment_dirty=false
if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then deployment_dirty=true; fi
printf '{"version":"%s","sourceCommit":"%s","dirty":%s,"apiMode":"same-origin"}\n' \
  "$deployment_version" "$deployment_revision" "$deployment_dirty" > build/web/deployment.json
