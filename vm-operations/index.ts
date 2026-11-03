// Day-2 operations on a Cloud VM: metrics, events, and a resize.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const vm_id = process.env.IBEE_VM_ID!;

/** Poll a VM operation until it finishes. */
async function wait({ operation_id }: { operation_id: string }) {
  for (;;) {
    const op = await ibee.cloudVms.getComputeOperation({ operation_id });
    if (["succeeded", "failed", "cancelled", "timed_out"].includes(op.status)) {
      return console.log(`${op.action}: ${op.status} ${op.error_message ?? ""}`);
    }
    await new Promise((resolve) => setTimeout(resolve, 10_000));
  }
}

const vm = await ibee.cloudVms.getCloudVm({ vm_id });
console.log(`${vm.name}: ${vm.status}, ${vm.cpu} vCPU, ${vm.ram_mb} MB`);

const metrics = await ibee.cloudVms.getCloudVmMetrics({ vm_id });
console.log(`CPU ${metrics.cpu_percent}%, memory ${metrics.memory_used_percent}%`);
for (const event of await ibee.cloudVms.listCloudVmEvents({ vm_id, limit: 5 })) {
  console.log(`${event.created_at}  ${event.event_type}  ${event.message}`);
}

// Resize CPU and memory. Stop the VM first; start it again afterwards.
await wait(await ibee.cloudVms.stopCloudVm({ vm_id, body: {} }));
await wait(
  await ibee.cloudVms.resizeCloudVm({
    vm_id,
    body: { cpu: Number(process.env.IBEE_NEW_CPU), ram_mb: Number(process.env.IBEE_NEW_RAM_MB) },
  }),
);
await wait(await ibee.cloudVms.startCloudVm({ vm_id, body: {} }));
