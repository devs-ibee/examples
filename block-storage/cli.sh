#!/usr/bin/env bash
# Block Storage with the ibee CLI: create, attach to a VM, grow, detach, delete.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, IBEE_SITE_ID, optional IBEE_ENV=dev
set -euo pipefail

VM_ID="$IBEE_VM_ID"

VOLUME_ID=$(ibee --json block-storage create "example-data-$RANDOM" \
  --size-gb 20 --site-id "$IBEE_SITE_ID" --class balanced | jq -r .volume.id)
ibee block-storage get "$VOLUME_ID"

ibee vms volume-attach "$VM_ID" "$VOLUME_ID" --wait
ibee vms mount-guidance-acknowledge "$VM_ID" "$VOLUME_ID"

ibee block-storage resize "$VOLUME_ID" --new-size-gb 30 --allow-online --vm-state running
ibee block-storage list

# Unmount the filesystem inside the VM before detaching.
ibee vms volume-detach "$VM_ID" "$VOLUME_ID" --confirm-unmounted --yes --wait
ibee block-storage delete "$VOLUME_ID" --yes
