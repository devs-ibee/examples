// Create a Block Storage volume, attach it to a Cloud VM, detach it, and delete it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const vm_id = process.env.IBEE_VM_ID!;
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/** Poll a VM operation until it finishes. */
async function wait({ operation_id }: { operation_id: string }) {
  for (;;) {
    const op = await ibee.cloudVms.getComputeOperation({ operation_id });
    if (["succeeded", "failed", "cancelled", "timed_out"].includes(op.status)) {
      return console.log(`${op.action}: ${op.status} ${op.error_message ?? ""}`);
    }
    await sleep(5_000);
  }
}

const created = await ibee.blockStorage.createBlockVolume({
  name: "example-data",
  size_gb: 20,
  site_id: process.env.IBEE_SITE_ID!, // the VM's site
  sku_code: process.env.IBEE_BLOCK_SKU!,
});
const volume_id = created.volume.id;
let volume = await ibee.blockStorage.getBlockVolume({ volume_id });
while (volume.state !== "ready") {
  await sleep(5_000);
  volume = await ibee.blockStorage.getBlockVolume({ volume_id });
}
console.log(`Volume ${volume.name} is ${volume.state}, ${volume.size_gb} GB`);

await wait(await ibee.cloudVms.attachCloudVmVolume({ vm_id, body: { volume_id } }));
// Format and mount it inside the VM now (see README.md). Unmount before detaching.
await wait(await ibee.cloudVms.detachCloudVmVolume({ vm_id, body: { volume_id, confirm_unmounted: true } }));

await ibee.blockStorage.deleteBlockVolume({ volume_id });
