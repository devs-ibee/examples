#!/usr/bin/env bash
# Secret Manager with plain HTTP calls: a store, a versioned secret, rollback, and an AppRole identity.
#
# Requires: curl, jq, openssl
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev, KEEP=1.
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

STORE_ID=$(api POST /secret-store/stores '{"name": "example-payments", "description": "Payment provider keys"}' | jq -r .id)

# A secret with two keys. Placeholder values stand in for real keys.
WEBHOOK="whsec_$(openssl rand -hex 12)"
VALUE() { jq -cn --arg key "sk_test_$(openssl rand -hex 12)" --arg hook "$WEBHOOK" '{API_KEY: $key, WEBHOOK_SECRET: $hook}'; }
SECRET_ID=$(api POST "/secret-store/stores/$STORE_ID/secrets" "$(jq -n --argjson v "$(VALUE)" '{secret_name: "stripe", value: $v}')" |
  jq -r .id)
api GET "/secret-store/secrets/$SECRET_ID/value" | jq '{secret_name, keys: (.data // {} | keys)}'

# Every update is a new version; roll back if a rotation goes wrong.
api PUT "/secret-store/secrets/$SECRET_ID/value" "$(jq -n --argjson v "$(VALUE)" '{value: $v}')" >/dev/null
api GET "/secret-store/secrets/$SECRET_ID/versions" | jq '{current_version, versions: (.versions | keys)}'
api POST "/secret-store/secrets/$SECRET_ID/rollback" '{"version": 1}' >/dev/null

# A read-only AppRole identity. Access details include a fresh secret ID; do not log it.
IDENTITY_ID=$(api POST "/secret-store/stores/$STORE_ID/identities" \
  '{"auth_method": "approle", "name": "payments-api", "token_policy_mode": "read_only"}' | jq -r .id)
api GET "/secret-store/identities/$IDENTITY_ID/access" | jq '{identity_id, auth_method, role_id}'

if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/secret-store/secrets/$SECRET_ID/permanent" >/dev/null
  api DELETE "/secret-store/identities/$IDENTITY_ID" >/dev/null
  api DELETE "/secret-store/stores/$STORE_ID/permanent" >/dev/null
  echo "Deleted the secret, identity, and store"
fi
