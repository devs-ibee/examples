#!/usr/bin/env bash
# Firewalls with the ibee CLI: a web-server group attached to a VM.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ADMIN_CIDR, IBEE_ENV=dev, KEEP=1
set -euo pipefail

GROUP_ID=$(ibee --json firewalls create web -d "HTTP, HTTPS, and admin SSH" | jq -r .firewall_group_id)

for PORT in 80 443; do
  ibee firewalls rules create "$GROUP_ID" --direction ingress --protocol tcp \
    --port-start "$PORT" --port-end "$PORT" --remote-target 0.0.0.0/0 --action allow
done

if [[ -n "${IBEE_ADMIN_CIDR:-}" ]]; then
  ibee firewalls rules create "$GROUP_ID" --direction ingress --protocol tcp \
    --port-start 22 --port-end 22 --remote-target "$IBEE_ADMIN_CIDR" --action allow -d "Admin SSH"
fi

ibee firewalls attachments attach "$GROUP_ID" "$IBEE_VM_ID"
ibee firewalls get "$GROUP_ID"
ibee firewalls attachments list "$GROUP_ID"

if [[ "${KEEP:-}" != "1" ]]; then
  ibee firewalls attachments detach "$GROUP_ID" "$IBEE_VM_ID" --yes
  ibee firewalls delete "$GROUP_ID" --yes
fi
