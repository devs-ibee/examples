#!/usr/bin/env bash
# Day-2 operations on a Cloud VM with the ibee CLI: metrics, events, and a resize.
set -euo pipefail

# Poll a VM operation until it finishes.
wait_op() {
  while true; do
    op=$(ibee --json ops get "$1")
    case $(jq -r .status <<<"$op") in
      succeeded | failed | cancelled | timed_out) jq -r '"\(.action): \(.status) \(.error_message // "")"' <<<"$op"; return ;;
    esac
    sleep 10
  done
}

ibee vms get "$IBEE_VM_ID"
ibee vms metrics "$IBEE_VM_ID"
ibee vms events "$IBEE_VM_ID" --limit 5

# Resize to another plan: its exact size, and --billing-interval HOURLY sends its
# billing_catalog with the HOURLY option merged in. Stop the VM first; start it again afterwards.
read -r CPU RAM_MB DISK_GB < <(ibee --json compute plans --vm-type cloud --site-id "$IBEE_SITE_ID" |
  jq -r --arg id "$IBEE_NEW_PLAN_ID" '.plans[] | select(.plan_id == $id) | "\(.cpu) \(.ram_mb) \(.disk_gb)"')
wait_op "$(ibee --json vms stop "$IBEE_VM_ID" | jq -r .operation_id)"
wait_op "$(ibee --json vms resize "$IBEE_VM_ID" --cpu "$CPU" --ram-mb "$RAM_MB" --disk-gb "$DISK_GB" \
  --plan-id "$IBEE_NEW_PLAN_ID" --billing-interval HOURLY | jq -r .operation_id)"
wait_op "$(ibee --json vms start "$IBEE_VM_ID" | jq -r .operation_id)"
