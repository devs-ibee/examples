#!/usr/bin/env bash
# Day-2 operations on a Cloud VM with the ibee CLI: metrics, events, and a resize.
set -euo pipefail

ibee vms get "$IBEE_VM_ID"
ibee vms metrics "$IBEE_VM_ID"
ibee vms events "$IBEE_VM_ID" --limit 5

ibee vms stop "$IBEE_VM_ID" --wait
ibee vms resize-plan "$IBEE_VM_ID" --plan-id "$IBEE_NEW_PLAN_ID" --billing-term HOURLY --wait
ibee vms start "$IBEE_VM_ID" --wait
