#!/usr/bin/env bash
# Create a Block Storage volume, attach it to a Cloud VM, detach it, and delete it with the ibee CLI.
set -euo pipefail

# Poll a VM operation until it finishes.
wait_op() {
  while true; do
    op=$(ibee --json ops get "$1")
    case $(jq -r .status <<<"$op") in
      succeeded | failed | cancelled | timed_out) jq -r '"\(.action): \(.status) \(.error_message // "")"' <<<"$op"; return ;;
    esac
    sleep 5
  done
}

VOLUME_ID=$(ibee --json block-storage create --name example-data --size-gb 20 \
  --site-id "$IBEE_SITE_ID" --sku-code "$IBEE_BLOCK_SKU" | jq -r .volume.id)
until [[ $(ibee --json block-storage get "$VOLUME_ID" | jq -r .state) == ready ]]; do sleep 5; done

# The attachment is billed under the volume's Block Storage SKU, from the volume's metadata.
CATALOG=$(ibee --json block-storage get "$VOLUME_ID" | jq -c .metadata.billing_catalog)
wait_op "$(ibee --json vms volume-attach "$IBEE_VM_ID" --volume-id "$VOLUME_ID" --billing-catalog "$CATALOG" | jq -r .operation_id)"
# Format and mount it inside the VM now (see README.md). Unmount before detaching.
wait_op "$(ibee --json vms volume-detach "$IBEE_VM_ID" --volume-id "$VOLUME_ID" --confirm-unmounted --yes | jq -r .operation_id)"

ibee block-storage delete "$VOLUME_ID" --yes
