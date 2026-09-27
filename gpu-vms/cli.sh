#!/usr/bin/env bash
# GPU plans and day-2 operations on an existing GPU VM with the ibee CLI.
# CLI 0.3.0 cannot create or delete GPU VMs; use main.py, index.ts, or api.sh for that.
#
# Requires: pip install ibee-cli
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID (a GPU VM), optional IBEE_ENV=dev
set -euo pipefail

VM_ID="$IBEE_VM_ID"

ibee compute plans --vm-type gpu
ibee compute images --vm-type gpu

ibee gpus list
ibee gpus get "$VM_ID"
ibee gpus metrics "$VM_ID"
ibee gpus stop "$VM_ID" --wait
ibee gpus start "$VM_ID" --wait
