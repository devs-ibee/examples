#!/usr/bin/env bash
# Create a Cloud VM, read it, and delete it with the ibee CLI.
set -euo pipefail

VM_ID=$(ibee --json vms create example-vm \
  --site-id "$IBEE_SITE_ID" --plan-id "$IBEE_PLAN_ID" --template-id "$IBEE_TEMPLATE_ID" \
  --billing-term HOURLY --wait | jq -r .vm_id)

ibee vms get "$VM_ID"
ibee vms delete "$VM_ID" --release-public-ip --yes --wait
