#!/usr/bin/env bash
# Snapshot a Cloud VM, list its recovery points, and delete the snapshot with the ibee CLI.
set -euo pipefail

# A snapshot is billed for its storage: send a snapshot storage plan's billing_catalog unchanged.
CATALOG=$(ibee --json compute snapshot-storage-plans |
  jq -c 'first(.items[] | select(.selectable)) | .billing_catalog')
SNAPSHOT_ID=$(ibee --json vms snapshots create "$IBEE_VM_ID" --name before-upgrade --mode root_only \
  --billing-catalog "$CATALOG" | jq -r .snapshot_set_id)

ibee vms snapshots list "$IBEE_VM_ID"
ibee vms backups list "$IBEE_VM_ID"
ibee vms snapshots delete "$SNAPSHOT_ID" --yes
