#!/usr/bin/env bash
# Object Storage with plain HTTP calls: a private bucket and a bucket-scoped access key.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev,
#              IBEE_STORAGE_REGION (default in-south-2), IBEE_BUCKET_NAME, KEEP=1.
# IBEE_API_URL overrides the API base URL.
set -euo pipefail

if [[ "${IBEE_ENV:-}" == "dev" ]]; then API="https://api.ibee.co.in/v1"; else API="https://api.ibee.ai/v1"; fi
API="${IBEE_API_URL:-$API}"

# api METHOD PATH [JSON_BODY] [EXTRA_HEADER]
# Sends the token as a bearer token and the workspace as the workspace_id query parameter.
api() {
  local method="$1" path="$2" body="${3:-}" header="${4:-}" sep="?"
  [[ "$path" == *\?* ]] && sep="&"
  curl -sS --fail-with-body -X "$method" \
    -H "Authorization: Bearer $IBEE_TOKEN" \
    -H "Content-Type: application/json" \
    ${header:+-H "$header"} \
    ${body:+--data "$body"} \
    "$API$path${sep}workspace_id=$IBEE_WORKSPACE_ID"
}

BUCKET="${IBEE_BUCKET_NAME:-example-$RANDOM$RANDOM}"

# 1. A private bucket.
api POST /object-storage/buckets "$(jq -n --arg name "$BUCKET" --arg region "${IBEE_STORAGE_REGION:-in-south-2}" \
  '{name: $name, region: $region, is_public: false, tags: ["example"]}')" | jq '{name, region, is_public}'

# 2. An access key that can only read and write objects in this bucket.
KEY=$(api POST /object-storage/credentials "$(jq -n --arg bucket "$BUCKET" '{
  name: "\($bucket)-app", permission_type: "object_rw", bucket_scope: "specific", allowed_buckets: [$bucket]
}')")
ACCESS_KEY_ID=$(jq -r .access_key_id <<<"$KEY")
echo "Access key ID:     $ACCESS_KEY_ID"
echo "Secret access key: $(jq -r .secret_access_key <<<"$KEY")   (shown only once)"
echo "S3 endpoint:       https://$IBEE_WORKSPACE_ID.blob.ibeestorage.com"

api GET /object-storage/buckets | jq -r '.buckets[]? | "  \(.name)  \(.object_count // 0) objects"'

# 3. Clean up. A bucket must be empty before it can be deleted.
if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/object-storage/credentials/$ACCESS_KEY_ID" >/dev/null
  api DELETE "/object-storage/buckets/$BUCKET" >/dev/null
  echo "Revoked the access key and deleted the bucket"
fi
