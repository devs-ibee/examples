"""Snapshot a Cloud VM, list its recovery points, and delete the snapshot."""

import os

from ibee import BillingCatalogSelection, Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
vms = client.cloud_vms
VM_ID = os.environ["IBEE_VM_ID"]

snapshot = vms.create_cloud_vm_snapshot(
    VM_ID,
    name="before-upgrade",
    mode="root_only",
    billing_catalog=BillingCatalogSelection(
        sku_id=os.environ["IBEE_SNAPSHOT_SKU_ID"], sku_code=os.environ["IBEE_SNAPSHOT_SKU_CODE"]
    ),
)
print(f"Snapshot {snapshot.snapshot_set_id} is {snapshot.status}")

for snap in vms.list_cloud_vm_snapshots(VM_ID).snapshots:
    print(f"snapshot  {snap.snapshot_set_id}  {snap.name}  {snap.status}")
for run in vms.list_cloud_vm_backup_runs(VM_ID).runs:
    print(f"backup    {run.run_id}  {run.status}  {run.started_at}")

vms.delete_cloud_vm_snapshot(snapshot.snapshot_set_id)
