#!/usr/bin/env bash
# Day-2 Cloud VM operations with the ibee CLI.
#
# Requires: pip install ibee-cli
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev
set -euo pipefail

VM_ID="$IBEE_VM_ID"

ibee vms metrics "$VM_ID"
ibee vms metrics-timeseries "$VM_ID" --range 1h
ibee vms bandwidth "$VM_ID" --month "$(date +%Y-%m)"
ibee vms events "$VM_ID"

# Check whether a resize to 4 vCPU / 8 GB is allowed before applying it.
ibee vms resize-precheck "$VM_ID" --cpu 4 --ram-mb 8192

# A short-lived browser console URL. Treat it like a password.
ibee --json console create "$VM_ID" --vm-type cloud | jq -r .connect_url
