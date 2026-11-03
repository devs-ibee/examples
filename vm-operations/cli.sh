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

# Resize CPU and memory. Stop the VM first; start it again afterwards.
wait_op "$(ibee --json vms stop "$IBEE_VM_ID" | jq -r .operation_id)"
wait_op "$(ibee --json vms resize "$IBEE_VM_ID" --cpu "$IBEE_NEW_CPU" --ram-mb "$IBEE_NEW_RAM_MB" | jq -r .operation_id)"
wait_op "$(ibee --json vms start "$IBEE_VM_ID" | jq -r .operation_id)"
