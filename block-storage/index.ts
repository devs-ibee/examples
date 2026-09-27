/**
 * Block Storage: create a volume, attach it to a VM, grow it, detach, and delete.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx block-storage/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, IBEE_SITE_ID,
 *              optional IBEE_BLOCK_SKU, IBEE_ENV=dev, KEEP=1
 */
import { randomUUID } from "node:crypto";
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const vmId = process.env.IBEE_VM_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const TERMINAL = new Set(["succeeded", "failed", "cancelled", "timed_out"]);

/** Poll an asynchronous VM operation until it finishes. */
async function waitFor(operationId: string) {
  for (;;) {
    const op = await client.operations.get({ workspaceId, operationId });
    if (TERMINAL.has(op.status)) {
      if (op.status !== "succeeded") throw new Error(`${op.action} ${op.status}: ${op.error_message}`);
      console.log(`  ${op.action}: succeeded`);
      return op;
    }
    await sleep(10_000);
  }
}

async function waitForVolume(volumeId: string, states = ["ready", "in-use"]) {
  for (let attempt = 0; attempt < 180; attempt++) {
    const volume = await client.blockStorage.getVolume({ workspaceId, volumeId });
    if (states.includes(volume.state)) return volume;
    if (volume.state === "error") throw new Error(`volume ${volumeId} is in error`);
    await sleep(5_000);
  }
  throw new Error(`volume ${volumeId} did not become ${states.join(" or ")}`);
}

// 1. Create a volume at the VM's site.
const created = await client.blockStorage.createVolume({
  workspaceId,
  name: `example-data-${randomUUID().slice(0, 6)}`,
  size_gb: 20,
  site_id: process.env.IBEE_SITE_ID!,
  sku_code: process.env.IBEE_BLOCK_SKU || undefined,
  volume_class: "balanced",
});
const volumeId = created.volume.id;
let volume = await waitForVolume(volumeId);
console.log(`Volume ${volume.name} (${volumeId}) is ${volume.state}, ${volume.size_gb} GB`);

// 2. Attach it to the VM.
await waitFor((await client.cloudVms.attachVolume({ workspaceId, vmId, request: { volume_id: volumeId } })).operation_id);
await client.cloudVms.acknowledgeMountGuidance({ workspaceId, vmId, volumeId });
console.log("Attached. Format and mount it inside the VM (see README.md).");

// 3. Grow the volume. Shrinking is not supported.
await client.blockStorage.resizeVolume({
  workspaceId,
  volumeId,
  request: { new_size_gb: 30, vm_state: "running", allow_online: true },
});
volume = await waitForVolume(volumeId);
console.log(`Resized to ${volume.size_gb} GB. Run resize2fs inside the VM to use the space.`);

// 4. Unmount inside the VM first, then detach and delete.
if (process.env.KEEP !== "1") {
  const detach = await client.cloudVms.detachVolume({
    workspaceId,
    vmId,
    request: { volume_id: volumeId, confirm_unmounted: true },
  });
  await waitFor(detach.operation_id);
  await waitForVolume(volumeId, ["ready"]);
  await client.blockStorage.deleteVolume({ workspaceId, volumeId });
  console.log(`Deleted ${volumeId}`);
}
