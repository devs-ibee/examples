#!/usr/bin/env bash
# CDN with the ibee CLI: distribution, SPA routing, custom domain, purge, signed URL.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BUCKET_NAME,
#              optional IBEE_DOMAIN, IBEE_ENV=dev, KEEP=1
set -euo pipefail

BUCKET="$IBEE_BUCKET_NAME"

DIST_ID=$(ibee --json cdn create "$BUCKET-site" --origin-id "$BUCKET" --cache-policy static-assets | jq -r .id)
ibee cdn get "$DIST_ID"
ibee cdn website set "$DIST_ID" --index-document index.html

if [[ -n "${IBEE_DOMAIN:-}" ]]; then
  ibee cdn domains create "$DIST_ID" "$IBEE_DOMAIN"   # prints the CNAME record to create
  ibee cdn domains verify "$DIST_ID" "$IBEE_DOMAIN"
fi

ibee cdn purge "$DIST_ID" --mode url --path /index.html
ibee cdn generate-url "$BUCKET" index.html --expires-in 3600

if [[ "${KEEP:-}" != "1" ]]; then
  ibee cdn delete "$DIST_ID" --yes
fi
