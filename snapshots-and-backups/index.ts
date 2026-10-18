// Snapshot a Cloud VM, list its recovery points, and delete the snapshot.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const vm_id = process.env.IBEE_VM_ID!;

const snapshot = await ibee.cloudVms.createCloudVmSnapshot({
  vm_id,
  body: {
    name: "before-upgrade",
    mode: "root_only",
    billing_catalog: { sku_id: process.env.IBEE_SNAPSHOT_SKU_ID!, sku_code: process.env.IBEE_SNAPSHOT_SKU_CODE! },
  },
});
console.log(`Snapshot ${snapshot.snapshot_set_id} is ${snapshot.status}`);

for (const snap of (await ibee.cloudVms.listCloudVmSnapshots({ vm_id })).snapshots) {
  console.log(`snapshot  ${snap.snapshot_set_id}  ${snap.name}  ${snap.status}`);
}
for (const run of (await ibee.cloudVms.listCloudVmBackupRuns({ vm_id })).runs) {
  console.log(`backup    ${run.run_id}  ${run.status}  ${run.started_at}`);
}

await ibee.cloudVms.deleteCloudVmSnapshot({ snapshot_set_id: snapshot.snapshot_set_id });
