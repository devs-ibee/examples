// Snapshot a Cloud VM, list its recovery points, and delete the snapshot.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const vm_id = process.env.IBEE_VM_ID!;

// A snapshot is billed for its storage: send a snapshot storage plan's billing_catalog unchanged.
const { items } = await ibee.computeCatalog.listSnapshotStoragePlans();
const storagePlan = items.find((p) => p.selectable)!;

const snapshot = await ibee.cloudVms.createCloudVmSnapshot({
  vm_id,
  body: { name: "before-upgrade", mode: "root_only", billing_catalog: storagePlan.billing_catalog },
});
console.log(`Snapshot ${snapshot.snapshot_set_id} is ${snapshot.status}`);

for (const snap of (await ibee.cloudVms.listCloudVmSnapshots({ vm_id })).snapshots) {
  console.log(`snapshot  ${snap.snapshot_set_id}  ${snap.name}  ${snap.status}`);
}
for (const run of (await ibee.cloudVms.listCloudVmBackupRuns({ vm_id })).runs) {
  console.log(`backup    ${run.run_id}  ${run.status}  ${run.started_at}`);
}

await ibee.cloudVms.deleteCloudVmSnapshot({ snapshot_set_id: snapshot.snapshot_set_id });
