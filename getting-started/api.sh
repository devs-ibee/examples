#!/usr/bin/env bash
# Verify credentials and discover sites, plans, images, and billing status
# with plain HTTP calls.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev
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

echo "Compute sites"
api GET /compute/sites | jq -r '.sites[] | "  \(.site_id)  \(.name)  \(.location // "")"'

echo "Cloud VM plans (priced, cheapest first)"
api GET "/compute/plans?vm_type=cloud" | jq -r '
  .plans | map(select(.selectable and .pricing_status == "priced")) | sort_by(.hourly_price_minor // 0) | .[:10][]
  | "  \(.plan_id)  \(.name)  \(.cpu) vCPU / \(.ram_mb / 1024) GB RAM  \((.hourly_price_minor // 0) / 100) \(.currency)/hour"'

echo "Cloud OS images"
api GET "/compute/images?vm_type=cloud" | jq -r '.images[] | "  \(.template_id)  \(.name)  (\(.os_distro))"'

echo "Networking sites"
api GET /networking/sites | jq -r '.[] | "  \(.site_id)  \(.site_name)  available=\(.available)"'

echo "Billing eligibility for a new bucket"
api POST /billing/resource-eligibility '{"sku_code": "OBJECTST-STD"}' | jq '{allowed, reason, billing_state}'
