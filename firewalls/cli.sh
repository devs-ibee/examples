#!/usr/bin/env bash
# Create a firewall group that allows HTTP and HTTPS, attach it to a VM, then remove it, with the ibee CLI.
set -euo pipefail

GROUP_ID=$(ibee --json firewalls create web --description "HTTP and HTTPS from anywhere" | jq -r .firewall_group_id)
for port in 80 443; do
  ibee firewalls rules create "$GROUP_ID" --direction ingress --protocol tcp --port "$port" \
    --remote-target 0.0.0.0/0 --action allow
done

ibee firewalls attachments attach "$GROUP_ID" "$IBEE_VM_ID"
ibee firewalls get "$GROUP_ID"

ibee firewalls attachments detach "$GROUP_ID" "$IBEE_VM_ID" --yes
ibee firewalls delete "$GROUP_ID" --yes
