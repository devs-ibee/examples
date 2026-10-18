#!/usr/bin/env bash
# Create a Block Storage volume, attach it to a Cloud VM, detach it, and delete it with the ibee CLI.
set -euo pipefail

VOLUME_ID=$(ibee --json block-storage create example-data --size-gb 20 \
  --site-id "$IBEE_SITE_ID" --sku-code "$IBEE_BLOCK_SKU" | jq -r .volume.id)
until [[ $(ibee --json block-storage get "$VOLUME_ID" | jq -r .state) == ready ]]; do sleep 5; done

ibee vms volume-attach "$IBEE_VM_ID" "$VOLUME_ID" --wait
# Format and mount it inside the VM now (see README.md). Unmount before detaching.
ibee vms volume-detach "$IBEE_VM_ID" "$VOLUME_ID" --confirm-unmounted --yes --wait

ibee block-storage delete "$VOLUME_ID" --yes
