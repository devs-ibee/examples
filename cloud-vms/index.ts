// Create a Cloud VM, read it, and delete it.
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
    await new Promise((resolve) => setTimeout(resolve, 10_000));
  }
}

// The request carries the plan's size and the image's OS, so read both first.
const { plans } = await ibee.computeCatalog.listComputePlans({ vm_type: "cloud", site_id });
const plan = plans.find((p) => p.plan_id === process.env.IBEE_PLAN_ID)!;
const { images } = await ibee.computeCatalog.listComputeImages({ vm_type: "cloud", site_id });
const image = images.find((i) => i.template_id === process.env.IBEE_TEMPLATE_ID)!;

const accepted = await ibee.cloudVms.createCloudVm({
  name: "example-vm",
  site_id,
  plan_id: plan.plan_id,
  template_id: image.template_id,
  os_type: image.os_type,
  os_distro: image.os_distro,
  cpu: plan.cpu,
  ram_mb: plan.ram_mb,
  billing_term: "HOURLY",
});
await wait(accepted);

const vm = await ibee.cloudVms.getCloudVm({ vm_id: accepted.vm_id });
console.log(`${vm.name} is ${vm.status}, public IP ${vm.public_ip}`);

await wait(await ibee.cloudVms.deleteCloudVm({ vm_id: accepted.vm_id, body: { public_ip_action: "release" } }));
