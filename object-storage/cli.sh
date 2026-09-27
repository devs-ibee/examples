#!/usr/bin/env bash
# Object Storage with the ibee CLI: a private bucket and a bucket-scoped access key.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev,
#              IBEE_STORAGE_REGION (default in-south-2), IBEE_BUCKET_NAME, KEEP=1
set -euo pipefail

BUCKET="${IBEE_BUCKET_NAME:-example-$RANDOM$RANDOM}"

ibee buckets create "$BUCKET" --region "${IBEE_STORAGE_REGION:-in-south-2}" --tag example
ibee buckets get "$BUCKET"

KEY=$(ibee --json buckets credentials create --name "$BUCKET-app" \
  --permission-type object_rw --bucket-scope specific --allowed-bucket "$BUCKET")
ACCESS_KEY_ID=$(jq -r .access_key_id <<<"$KEY")
echo "Access key ID:     $ACCESS_KEY_ID"
echo "Secret access key: $(jq -r .secret_access_key <<<"$KEY")   (shown only once)"
echo "S3 endpoint:       https://$IBEE_WORKSPACE_ID.blob.ibeestorage.com"

ibee buckets list
ibee buckets credentials list

if [[ "${KEEP:-}" != "1" ]]; then
  ibee buckets credentials revoke "$ACCESS_KEY_ID" --yes
  ibee buckets delete "$BUCKET" --yes
fi
