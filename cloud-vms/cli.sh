#!/usr/bin/env bash
# Day-2 operations on an existing Cloud VM with the ibee CLI.
#
# Requires: pip install ibee-cli
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev
set -euo pipefail

VM_ID="$IBEE_VM_ID"

ibee vms list
ibee vms get "$VM_ID"
ibee vms metrics "$VM_ID"
ibee vms events "$VM_ID"

# Power actions return an operation; --wait polls it until it finishes.
ibee vms stop "$VM_ID" --wait
ibee vms start "$VM_ID" --wait

# A short-lived browser console URL. Treat it like a password.
ibee --json console create "$VM_ID" --vm-type cloud | jq -r .connect_url
