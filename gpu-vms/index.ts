// Create a GPU VM, read it, and delete it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const site_id = process.env.IBEE_SITE_ID!;

/** Poll a VM operation until it finishes. */
async function wait({ operation_id }: { operation_id: string }) {
  for (;;) {
    const op = await ibee.cloudVms.getComputeOperation({ operation_id });
    if (["succeeded", "failed", "cancelled", "timed_out"].includes(op.status)) {
      return console.log(`${op.action}: ${op.status} ${op.error_message ?? ""}`);
    }
    await new Promise((resolve) => setTimeout(resolve, 15_000));
  }
}

// The request carries the plan's size and GPUs and the image's OS, so read both first.
const { plans } = await ibee.computeCatalog.listComputePlans({ vm_type: "gpu", site_id });
const plan = plans.find((p) => p.plan_id === process.env.IBEE_GPU_PLAN_ID)!;
const { images } = await ibee.computeCatalog.listComputeImages({ vm_type: "gpu", site_id });
const image = images.find((i) => i.template_id === process.env.IBEE_GPU_TEMPLATE_ID)!;

const accepted = await ibee.gpuVms.createGpuVm({
  name: "example-gpu",
  site_id,
  plan_id: plan.plan_id,
  template_id: image.template_id,
  os_type: "linux",
  os_distro: image.os_distro,
  cpu: plan.cpu,
  ram_mb: plan.ram_mb,
  gpu_count: plan.gpu_count,
  gpu_model: plan.gpu_model!,
  billing_term: "HOURLY",
});
await wait(accepted);

const vm = await ibee.gpuVms.getGpuVm({ vm_id: accepted.vm_id });
console.log(`${vm.name} is ${vm.status}: ${vm.gpu_count} x ${vm.gpu_model}, public IP ${vm.public_ip}`);

await wait(await ibee.gpuVms.deleteGpuVm({ vm_id: accepted.vm_id, body: { public_ip_action: "release" } }));
