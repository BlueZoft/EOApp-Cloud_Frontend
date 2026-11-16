#!/bin/sh
set -eu
if ! printf '%s' "${SERVER_NAME:-}" | grep -Eq '^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$' \
    || [ "${#SERVER_NAME}" -gt 253 ]; then
    echo 'Set SERVER_NAME to one hostname without a scheme, path or port.' >&2; exit 1
fi
case "$SERVER_NAME" in *example.invalid*|*REPLACE_WITH*|*..*)
    echo 'Replace the deployment hostname placeholder.' >&2; exit 1;; esac
if ! printf '%s' "${PUBLIC_ORIGIN:-}" | grep -Eq '^https://[a-z0-9.-]+(:[0-9]{1,5})?$'; then
    echo 'Set PUBLIC_ORIGIN to an HTTPS origin without a trailing slash.' >&2; exit 1
fi
deployment_authority=${PUBLIC_ORIGIN#https://}
deployment_host=${deployment_authority%%:*}
if [ "$deployment_host" != "$SERVER_NAME" ]; then
    echo 'PUBLIC_ORIGIN hostname must match SERVER_NAME.' >&2; exit 1
fi
case "$deployment_authority" in *:*)
    deployment_port=${deployment_authority##*:}
    if [ "$deployment_port" = 443 ]; then
        echo "Omit the default :443 port from PUBLIC_ORIGIN so browser origins match." >&2; exit 1
    fi
    if [ "$deployment_port" -lt 1 ] || [ "$deployment_port" -gt 65535 ]; then
        echo 'PUBLIC_ORIGIN port must be 1–65535.' >&2; exit 1
    fi;; esac
if [ ! -r /etc/nginx/tls/fullchain.pem ] || [ ! -r /etc/nginx/tls/privkey.pem ]; then
    echo 'Mount readable fullchain.pem and privkey.pem TLS files. See deploy/README.md.' >&2; exit 1
fi
