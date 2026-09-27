"""Enable scheduled backups, run one now, take a snapshot, and list recovery points.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (vm.read, vm.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_VM_ID         the Cloud VM to protect
  IBEE_ENV           "dev" to use the development API (optional)
"""

import datetime
import os

from ibee import BackupPolicySchedule, Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
VM_ID = os.environ["IBEE_VM_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
vms = client.cloud_vms

# 1. Daily backups at 20:00 UTC, keeping seven days of recovery points.
policy = vms.enable_cloud_vm_backups(
    vm_id=VM_ID,
    workspace_id=WORKSPACE_ID,
    schedule=BackupPolicySchedule(frequency="daily", timezone="UTC", hour=20, minute=0),
    retention_days=7,
    incremental_enabled=True,
)
print(f"Backups enabled: policy {policy.policy_id}, next run at {policy.next_run_at}")

# 2. An on-demand backup, in addition to the schedule.
run = vms.create_cloud_vm_backup_run(vm_id=VM_ID, workspace_id=WORKSPACE_ID, reason="before upgrade")
print(f"Backup run {run.run_id} is {run.status}")

# 3. A snapshot of the root disk. Use mode="all_attached" to include data volumes.
snapshot = vms.create_cloud_vm_snapshot(
    vm_id=VM_ID,
    workspace_id=WORKSPACE_ID,
    name=f"before-upgrade-{datetime.date.today():%Y%m%d}",
    mode="root_only",
)
print(f"Snapshot {snapshot.snapshot_set_id} is {snapshot.status}")

# 4. Recovery points you can restore from.
for backup in vms.list_cloud_vm_backup_runs(vm_id=VM_ID, workspace_id=WORKSPACE_ID, limit=10).runs:
    print(f"Backup {backup.run_id}: {backup.status}, recovery point {backup.recovery_point_id}, started {backup.started_at}")
for snap in vms.list_cloud_vm_snapshots(vm_id=VM_ID, workspace_id=WORKSPACE_ID, limit=10).snapshots:
    print(f"Snapshot {snap.snapshot_set_id}: {snap.name}, {snap.status}, {snap.display_size_gb} GB")
