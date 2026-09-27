#!/usr/bin/env bash
# Reserved IPs with the ibee CLI: reserve, attach, move, detach, release.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_SITE_ID, IBEE_VM_ID, IBEE_VPC_ID,
#              IBEE_SUBNET_ID, optional IBEE_NEW_VM_ID, IBEE_ENV=dev, KEEP=1
set -euo pipefail

IP_ID=$(ibee --json reserved-ips reserve --site-id "$IBEE_SITE_ID" --label example-web | jq -r .public_ip_id)
ibee reserved-ips attach "$IP_ID" "$IBEE_VM_ID" --vpc-id "$IBEE_VPC_ID" --subnet-id "$IBEE_SUBNET_ID"

if [[ -n "${IBEE_NEW_VM_ID:-}" ]]; then
  ibee reserved-ips move "$IP_ID" "$IBEE_NEW_VM_ID" --vpc-id "$IBEE_VPC_ID" --subnet-id "$IBEE_SUBNET_ID"
fi

ibee reserved-ips get "$IP_ID"
ibee reserved-ips list --site-id "$IBEE_SITE_ID"

if [[ "${KEEP:-}" != "1" ]]; then
  ibee reserved-ips detach "$IP_ID"
  ibee reserved-ips release "$IP_ID" --yes
fi
