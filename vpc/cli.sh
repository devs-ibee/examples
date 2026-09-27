#!/usr/bin/env bash
# Private networking with the ibee CLI: NAT-gateway VPC, subnet, VM attachment, port forwarding.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_SITE_ID, IBEE_ENV=dev, KEEP=1
set -euo pipefail

VM_ID="$IBEE_VM_ID"
SITE_ID="${IBEE_SITE_ID:-$(ibee --json vpcs sites | jq -r '[.[] | select(.available)][0].site_id')}"

VPC_ID=$(ibee --json vpcs create example-network --site-id "$SITE_ID" \
  --cidr 10.44.0.0/22 --no-auto-cidr --no-default-subnet --connectivity nat_gateway | jq -r .vpc_id)
SUBNET_ID=$(ibee --json vpcs subnets create "$VPC_ID" applications \
  --cidr 10.44.0.0/24 --no-auto-cidr | jq -r .subnet_id)

PRIVATE_IP=$(ibee --json vpcs nodes attach "$VPC_ID" "$VM_ID" \
  --subnet-id "$SUBNET_ID" --connectivity nat | jq -r .private_ip)
echo "VM $VM_ID has private IP $PRIVATE_IP"

NAT=$(ibee --json vpcs nat list "$VPC_ID" | jq -c '.[0]')
NAT_ID=$(jq -r .nat_gateway_id <<<"$NAT")
RULE_ID=$(ibee --json vpcs forwarding create "$VPC_ID" "$NAT_ID" ssh \
  --external-port 2222 --internal-ip "$PRIVATE_IP" --internal-port 22 | jq -r .port_forward_rule_id)
echo "Connect with: ssh -p 2222 <user>@$(jq -r .public_ip <<<"$NAT")"

ibee vpcs get "$VPC_ID"

if [[ "${KEEP:-}" != "1" ]]; then
  ibee vpcs forwarding delete "$VPC_ID" "$NAT_ID" "$RULE_ID" --yes
  ibee vpcs nodes detach "$VPC_ID" "$VM_ID" --yes
  ibee vpcs subnets delete "$VPC_ID" "$SUBNET_ID" --yes
  ibee vpcs delete "$VPC_ID" --yes
fi
