#!/usr/bin/env bash
# Put the CDN in front of a public bucket, purge a path, and delete the distribution, with the ibee CLI.
set -euo pipefail

DISTRIBUTION_ID=$(ibee --json cdn create --name example-site --origin-type bucket --origin-id "$IBEE_BUCKET_NAME" | jq -r .id)

ibee cdn website set "$DISTRIBUTION_ID" --index-document index.html
ibee cdn purge "$DISTRIBUTION_ID" --mode url --paths /index.html --yes
ibee cdn delete "$DISTRIBUTION_ID" --yes
