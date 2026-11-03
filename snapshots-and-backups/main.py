"""Snapshot a Cloud VM, list its recovery points, and delete the snapshot."""

import os

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
vms = client.cloud_vms
VM_ID = os.environ["IBEE_VM_ID"]

# A snapshot is billed for its storage: send a snapshot storage plan's billing_catalog unchanged.
storage_plans = client.compute_catalog.list_snapshot_storage_plans().items
storage_plan = next(p for p in storage_plans if p.selectable)

snapshot = vms.create_cloud_vm_snapshot(
    VM_ID, name="before-upgrade", mode="root_only", billing_catalog=storage_plan.billing_catalog
)
print(f"Snapshot {snapshot.snapshot_set_id} is {snapshot.status}")

for snap in vms.list_cloud_vm_snapshots(VM_ID).snapshots:
    print(f"snapshot  {snap.snapshot_set_id}  {snap.name}  {snap.status}")
for run in vms.list_cloud_vm_backup_runs(VM_ID).runs:
    print(f"backup    {run.run_id}  {run.status}  {run.started_at}")

vms.delete_cloud_vm_snapshot(snapshot.snapshot_set_id)
