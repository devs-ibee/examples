#!/usr/bin/env bash
# Reserved IPs with plain HTTP calls: reserve, attach, move, detach, release.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_SITE_ID, IBEE_VM_ID, IBEE_VPC_ID,
#              IBEE_SUBNET_ID, optional IBEE_NEW_VM_ID, IBEE_ENV=dev, KEEP=1.
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

placement() {  # placement VM_ID -> attach/move body
  jq -n --arg vm "$1" --arg vpc "${IBEE_VPC_ID:-}" --arg subnet "${IBEE_SUBNET_ID:-}" \
    '{vm_id: $vm} + (if $vpc == "" then {} else {vpc_id: $vpc} end) + (if $subnet == "" then {} else {subnet_id: $subnet} end)'
}

# 1. Reserve an address.
IP=$(api POST /networking/reserved-ips "$(jq -n --arg site "$IBEE_SITE_ID" '{site_id: $site, label: "example-web"}')")
IP_ID=$(jq -r .public_ip_id <<<"$IP")
echo "Reserved $(jq -r .address <<<"$IP") ($IP_ID)"

# 2. Attach it to a VM.
api POST "/networking/reserved-ips/$IP_ID/attach" "$(placement "$IBEE_VM_ID")" >/dev/null

# 3. Move it to a replacement VM without changing the address.
if [[ -n "${IBEE_NEW_VM_ID:-}" ]]; then
  api POST "/networking/reserved-ips/$IP_ID/move" "$(placement "$IBEE_NEW_VM_ID")" >/dev/null
fi
api GET "/networking/reserved-ips/$IP_ID" | jq '{address, status, attached_resource_id}'

# 4. Detach and release.
if [[ "${KEEP:-}" != "1" ]]; then
  api POST "/networking/reserved-ips/$IP_ID/detach" >/dev/null
  api DELETE "/networking/reserved-ips/$IP_ID" >/dev/null
  echo "Released $IP_ID"
fi
