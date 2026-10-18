#!/usr/bin/env bash
# Create a GPU VM, read it, and delete it with the ibee CLI.
set -euo pipefail

VM_ID=$(ibee --json gpus create example-gpu \
  --site-id "$IBEE_SITE_ID" --plan-id "$IBEE_GPU_PLAN_ID" --template-id "$IBEE_GPU_TEMPLATE_ID" \
  --billing-term HOURLY --wait --timeout 3600 | jq -r .vm_id)

ibee gpus get "$VM_ID"
ibee gpus delete "$VM_ID" --release-public-ip --yes --wait
