#!/usr/bin/env bash
# Snapshot a Cloud VM, list its recovery points, and delete the snapshot with the ibee CLI.
set -euo pipefail

CATALOG=$(jq -nc --arg id "$IBEE_SNAPSHOT_SKU_ID" --arg code "$IBEE_SNAPSHOT_SKU_CODE" '{sku_id: $id, sku_code: $code}')
SNAPSHOT_ID=$(ibee --json vms snapshots create "$IBEE_VM_ID" before-upgrade --mode root_only \
  --billing-catalog "$CATALOG" | jq -r .snapshot_set_id)

ibee vms snapshots list "$IBEE_VM_ID"
ibee vms backups list "$IBEE_VM_ID"
ibee vms snapshots delete "$SNAPSHOT_ID" --yes
