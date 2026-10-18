#!/usr/bin/env bash
# Create a private bucket and an S3 access key for it, then delete both, with the ibee CLI.
set -euo pipefail

ibee buckets create "$IBEE_BUCKET_NAME" --region "$IBEE_STORAGE_REGION"
KEY_ID=$(ibee --json buckets credentials create --name "$IBEE_BUCKET_NAME-app" \
  --permission-type object_rw --bucket-scope specific --allowed-bucket "$IBEE_BUCKET_NAME" | jq -r .access_key_id)

ibee buckets list
ibee buckets credentials revoke "$KEY_ID" --yes
ibee buckets delete "$IBEE_BUCKET_NAME" --yes
