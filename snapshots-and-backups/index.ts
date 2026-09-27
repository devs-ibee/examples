/**
 * Enable scheduled backups, run one now, take a snapshot, and list recovery points.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx snapshots-and-backups/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const vmId = process.env.IBEE_VM_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const vms = client.cloudVms;

// 1. Daily backups at 20:00 UTC, keeping seven days of recovery points.
const policy = await vms.enableBackups({
  workspaceId,
  vmId,
  request: {
    schedule: { frequency: "daily", timezone: "UTC", hour: 20, minute: 0 },
    retention_days: 7,
    incremental_enabled: true,
  },
});
console.log(`Backups enabled: policy ${policy.policy_id}`);

// 2. An on-demand backup, in addition to the schedule.
const run = await vms.createBackupRun({ workspaceId, vmId, request: { reason: "before upgrade" } });
console.log(`Backup run ${run.run_id} is ${run.status}`);

// 3. A snapshot of the root disk. Use mode "all_attached" to include data volumes.
const date = new Date().toISOString().slice(0, 10).replaceAll("-", "");
const snapshot = await vms.createSnapshot({ workspaceId, vmId, request: { name: `before-upgrade-${date}`, mode: "root_only" } });
console.log(`Snapshot ${snapshot.snapshot_set_id} is ${snapshot.status}`);

// 4. Recovery points you can restore from.
for (const backup of (await vms.listBackupRuns({ workspaceId, vmId, limit: 10 })).runs) {
  console.log(`Backup ${backup.run_id}: ${backup.status}, recovery point ${backup.recovery_point_id}`);
}
for (const snap of (await vms.listSnapshots({ workspaceId, vmId, limit: 10 })).snapshots) {
  console.log(`Snapshot ${snap.snapshot_set_id}: ${snap.name}, ${snap.status}`);
}
