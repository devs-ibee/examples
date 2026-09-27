#!/usr/bin/env bash
# Private networking with plain HTTP calls: NAT-gateway VPC, subnet, VM attachment, port forwarding.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_SITE_ID,
#              IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
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

# Wait until a VPC or subnet reports "available".
wait_available() {
  local path="$1" status
  for _ in $(seq 1 120); do
    status=$(api GET "$path" | jq -r .status)
    [[ "$status" == "available" ]] && return 0
    [[ "$status" == "error" ]] && { echo "$path is in error" >&2; return 1; }
    sleep 5
  done
  echo "$path is still $status" >&2
  return 1
}

SITE_ID="${IBEE_SITE_ID:-$(api GET /networking/sites | jq -r '[.[] | select(.available)][0].site_id')}"

# 1. A VPC whose managed NAT gateway is created with it.
VPC_ID=$(api POST /networking/vpcs "$(jq -n --arg site "$SITE_ID" '{
  name: "example-network", site_id: $site, cidr: "10.44.0.0/22", auto_cidr: false,
  create_default_subnet: false, connectivity_type: "nat_gateway"
}')" | jq -r .vpc_id)
wait_available "/networking/vpcs/$VPC_ID"

# 2. A subnet for application VMs.
SUBNET_ID=$(api POST "/networking/vpcs/$VPC_ID/subnets" \
  '{"name": "applications", "cidr": "10.44.0.0/24", "auto_cidr": false}' | jq -r .subnet_id)
wait_available "/networking/vpcs/$VPC_ID/subnets/$SUBNET_ID"

# 3. Attach the VM with outbound internet through NAT.
PRIVATE_IP=$(api POST "/networking/vpcs/$VPC_ID/nodes" "$(jq -n --arg vm "$IBEE_VM_ID" --arg subnet "$SUBNET_ID" \
  '{vm_id: $vm, subnet_id: $subnet, connectivity: "nat"}')" | jq -r .private_ip)
echo "VM $IBEE_VM_ID has private IP $PRIVATE_IP"

# 4. Forward NAT port 2222 to SSH on the VM.
NAT=$(api GET "/networking/vpcs/$VPC_ID/nat-gateways" | jq -c '.[0]')
NAT_ID=$(jq -r .nat_gateway_id <<<"$NAT")
RULE_ID=$(api POST "/networking/vpcs/$VPC_ID/nat-gateways/$NAT_ID/port-forwarding-rules" "$(jq -n --arg ip "$PRIVATE_IP" \
  '{name: "ssh", protocol: "tcp", external_port: 2222, internal_ip: $ip, internal_port: 22}')" | jq -r .port_forward_rule_id)
echo "Connect with: ssh -p 2222 <user>@$(jq -r .public_ip <<<"$NAT")"

# 5. Clean up in reverse order. Deleting the VPC also removes its NAT gateway.
if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/networking/vpcs/$VPC_ID/nat-gateways/$NAT_ID/port-forwarding-rules/$RULE_ID" >/dev/null
  api DELETE "/networking/vpcs/$VPC_ID/nodes/$IBEE_VM_ID" >/dev/null
  api DELETE "/networking/vpcs/$VPC_ID/subnets/$SUBNET_ID" >/dev/null
  api DELETE "/networking/vpcs/$VPC_ID" >/dev/null
  echo "Removed the forwarding rule, attachment, subnet, and VPC"
fi
