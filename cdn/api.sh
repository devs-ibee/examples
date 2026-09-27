#!/usr/bin/env bash
# CDN with plain HTTP calls: distribution, SPA routing, custom domain, purge, signed URL.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BUCKET_NAME,
#              optional IBEE_DOMAIN, IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
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

BUCKET="$IBEE_BUCKET_NAME"

# 1. A distribution in front of the bucket.
DIST=$(api POST /cdn/distributions "$(jq -n --arg b "$BUCKET" \
  '{name: "\($b)-site", origin_type: "bucket", origin_id: $b, cache_policy: "static-assets"}')")
DIST_ID=$(jq -r .id <<<"$DIST")
echo "Distribution $DIST_ID: $(jq -r .default_url <<<"$DIST")"

# 2. Single-page-app routing: unknown paths return index.html.
api PUT "/cdn/distributions/$DIST_ID/website-config" '{"index_document": "index.html"}' | jq '{enabled, index_document}'

# 3. Your own domain. Create the DNS record it returns, then verify.
if [[ -n "${IBEE_DOMAIN:-}" ]]; then
  api POST "/cdn/distributions/$DIST_ID/custom-domains" "$(jq -n --arg d "$IBEE_DOMAIN" '{domain: $d}')" |
    jq -r '"\(.domain) is \(.status). Create this DNS record:", (.instructions // [])[]'
  api POST "/cdn/distributions/$DIST_ID/custom-domains/$IBEE_DOMAIN/verify" | jq '{domain, status, message}'
fi

# 4. After each deploy, purge the files that changed.
api POST "/cdn/distributions/$DIST_ID/purge" '{"mode": "url", "paths": ["/index.html"]}' | jq '{success, purged}'

# 5. A signed CDN link for one object, valid for one hour.
api POST /cdn/generate-url "$(jq -n --arg b "$BUCKET" '{bucket_name: $b, object_key: "index.html", expires_in: 3600}')" |
  jq -r .cdn_url

if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/cdn/distributions/$DIST_ID" >/dev/null
  echo "Deleted $DIST_ID"
fi
