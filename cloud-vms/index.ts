/**
 * Cloud VM lifecycle: create, wait, stop, start, and delete.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx cloud-vms/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev,
 *              IBEE_SITE_ID, IBEE_SSH_KEY_ID, KEEP=1
 */
import { randomUUID } from "node:crypto";
import { Ibee, IbeeEnvironment, type ComputePlan, type CreateVmRequest } from "ibee-sdk";

const token = process.env.IBEE_TOKEN!;
const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const baseUrl = process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT;
const client = new Ibee({ token, environment: baseUrl });

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const TERMINAL = new Set(["succeeded", "failed", "cancelled", "timed_out"]);

/** Poll an asynchronous VM operation until it finishes. */
async function waitFor(operationId: string, timeoutMs = 30 * 60_000) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const op = await client.operations.get({ workspaceId, operationId });
    if (TERMINAL.has(op.status)) {
      if (op.status !== "succeeded") throw new Error(`${op.action} ${op.status}: ${op.error_code} ${op.error_message}`);
      console.log(`  ${op.action}: succeeded`);
      return op;
    }
    if (Date.now() > deadline) throw new Error(`operation ${operationId} is still ${op.status}`);
    console.log(`  ${op.action}: ${op.status} ${op.current_step ?? ""}`);
    await sleep(10_000);
  }
}

// 1. Site, plan, and image, chosen the way the portal's deploy page does.
const siteId = process.env.IBEE_SITE_ID ?? (await client.computeCatalog.listSites({ workspaceId })).sites[0].site_id;
const { plans } = await client.computeCatalog.listPlans({ workspaceId, vmType: "cloud", siteId });
const plan = plans
  .filter((p) => p.selectable && p.pricing_status === "priced")
  .sort((a, b) => (a.hourly_price_minor ?? 0) - (b.hourly_price_minor ?? 0))[0];
const { images } = await client.computeCatalog.listImages({ workspaceId, vmType: "cloud", siteId });
const image = images.find((i) => i.os_distro === "ubuntu") ?? images[0];

// The plan carries a billing_catalog object that must be sent back unchanged.
const billingCatalog = (plan as ComputePlan & { billing_catalog?: Record<string, unknown> }).billing_catalog;
if (!billingCatalog) throw new Error(`plan ${plan.plan_id} has no billing_catalog; choose another plan`);
console.log(`Plan ${plan.name} (${plan.cpu} vCPU, ${plan.ram_mb} MB RAM) with image ${image.name} at site ${siteId}`);

// 2. Create the VM. SDK 0.3.0 has no billing_catalog field yet, so add it to the request body.
const name = `example-vm-${randomUUID().slice(0, 6)}`;
const request: CreateVmRequest & { billing_catalog: Record<string, unknown> } = {
  name,
  site_id: siteId,
  plan_id: plan.plan_id,
  template_id: image.template_id,
  os_distro: image.os_distro,
  os_type: image.os_type,
  cpu: plan.cpu,
  ram_mb: plan.ram_mb,
  disk_gb: plan.disk_gb,
  ssh_key_ids: process.env.IBEE_SSH_KEY_ID ? [process.env.IBEE_SSH_KEY_ID] : [],
  tags: ["example"],
  billing_catalog: billingCatalog,
};
const accepted = await client.cloudVms.create({ workspaceId, idempotencyKey: `create-${name}`, ...request });
const vmId = accepted.vm_id;
console.log(`Creating ${name} (${vmId})`);
await waitFor(accepted.operation_id);

const vm = await client.cloudVms.get({ workspaceId, vmId });
console.log(`${vm.name} is ${vm.status}; public IP ${vm.public_ip}, private IP ${vm.private_ip}`);

// 3. Power actions.
console.log("Stopping");
await waitFor((await client.cloudVms.stop({ workspaceId, vmId })).operation_id);
console.log("Starting");
await waitFor((await client.cloudVms.start({ workspaceId, vmId })).operation_id);

// 4. Delete the VM and release its automatic public IP. SDK 0.3.0 cannot send
//    a delete body, so call the endpoint directly.
if (process.env.KEEP === "1") {
  console.log(`Keeping ${vmId}`);
} else {
  console.log("Deleting");
  const response = await fetch(`${baseUrl}/compute/cloud-vms/${vmId}?workspace_id=${workspaceId}`, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "X-Idempotency-Key": `delete-${vmId}`,
    },
    body: JSON.stringify({ public_ip_action: "release" }), // or "reserve" to keep the IP
  });
  if (!response.ok) throw new Error(`delete failed: ${response.status} ${await response.text()}`);
  const deleted = (await response.json()) as { operation_id: string };
  await waitFor(deleted.operation_id);
}
