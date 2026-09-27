#!/usr/bin/env bash
# Reserve a Virtual IP for MetalLB with plain HTTP calls.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VPC_ID, IBEE_SUBNET_ID,
#              IBEE_VIRTUAL_IP, IBEE_ANNOUNCER_VM_IDS (comma-separated),
#              optional IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
set -euo pipefail

if [[ "${IBEE_ENV:-}" == "dev" ]]; then API="https://api.ibee.co.in/v1"; else API="https://api.ibee.ai/v1"; fi
API="${IBEE_API_URL:-$API}"
VPC_ID="${IBEE_VPC_ID:-vpc-example}"
SUBNET_ID="${IBEE_SUBNET_ID:-subnet-example}"
VIRTUAL_IP="${IBEE_VIRTUAL_IP:-10.44.0.50}"
ANNOUNCERS="${IBEE_ANNOUNCER_VM_IDS:-$IBEE_VM_ID}"

api() {
  local method="$1" path="$2" body="${3:-}" sep="?"
  [[ "$path" == *\?* ]] && sep="&"
  curl -sS --fail-with-body -X "$method" \
    -H "Authorization: Bearer $IBEE_TOKEN" \
    -H "Content-Type: application/json" \
    ${body:+--data "$body"} \
    "$API$path${sep}workspace_id=$IBEE_WORKSPACE_ID"
}

# 1. Addresses already in use in the VPC.
echo "Allocated addresses:"
api GET "/networking/vpcs/$VPC_ID/network-allocations" |
  jq -r '(if type == "array" then . else (.items // []) end)[] | "  \(.private_ip)  \(.subnet_id)"'

# 2. Reserve the address for MetalLB and authorize the announcer nodes.
BODY=$(jq -n --arg subnet "$SUBNET_ID" --arg ip "$VIRTUAL_IP" --arg vms "$ANNOUNCERS" '{
  subnet_id: $subnet,
  private_ip: $ip,
  purpose: "metallb",
  announcer_vm_ids: ($vms | split(","))
}')
VIP=$(api POST "/networking/vpcs/$VPC_ID/virtual-ips" "$BODY")
VIP_ID=$(jq -r '.virtual_ip_id // .vip_id // .id' <<<"$VIP")
echo "Reserved $VIRTUAL_IP as Virtual IP $VIP_ID"

# 3. List and read back.
api GET "/networking/vpcs/$VPC_ID/virtual-ips" |
  jq 'if type == "array" then . else (.items // .virtual_ips // .vips // []) end'
api GET "/networking/vpcs/$VPC_ID/virtual-ips/$VIP_ID" | jq .

# 4. Release. Detach any Reserved IP from the Virtual IP first.
if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/networking/vpcs/$VPC_ID/virtual-ips/$VIP_ID" >/dev/null
  echo "Released $VIRTUAL_IP"
fi
