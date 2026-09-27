/**
 * GPU VM lifecycle: create from a GPU plan, wait, then delete.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx gpu-vms/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev, IBEE_SITE_ID,
 *              IBEE_GPU_MODEL, IBEE_SSH_KEY_ID, KEEP=1
 */
import { randomUUID } from "node:crypto";
import { Ibee, IbeeEnvironment, type ComputePlan, type CreateGpuVmRequest } from "ibee-sdk";

const token = process.env.IBEE_TOKEN!;
const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const baseUrl = process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT;
const client = new Ibee({ token, environment: baseUrl });
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

async function pricedGpuPlans(siteId: string) {
  const { plans } = await client.computeCatalog.listPlans({ workspaceId, vmType: "gpu", siteId });
  return plans
    .filter((p) => p.selectable && p.pricing_status === "priced" && p.gpu_count > 0)
    .sort((a, b) => (a.hourly_price_minor ?? 0) - (b.hourly_price_minor ?? 0));
}

// 1. The first site that offers priced GPU plans.
const siteIds = process.env.IBEE_SITE_ID
  ? [process.env.IBEE_SITE_ID]
  : (await client.computeCatalog.listSites({ workspaceId })).sites.map((s) => s.site_id);
let siteId = "";
let plan: ComputePlan | undefined;
for (const candidate of siteIds) {
  [plan] = await pricedGpuPlans(candidate);
  if (plan) {
    siteId = candidate;
    break;
  }
}
if (!plan) throw new Error("No priced GPU plans are available to this workspace. Contact support for GPU access.");
const gpuModel = plan.gpu_model ?? process.env.IBEE_GPU_MODEL;
if (!gpuModel) throw new Error(`Plan ${plan.plan_id} does not report its GPU model; set IBEE_GPU_MODEL`);
const { images } = await client.computeCatalog.listImages({ workspaceId, vmType: "gpu", siteId });
const image = images.find((i) => i.gpu_compatible && i.os_distro === "ubuntu") ?? images[0];
console.log(`${plan.name}: ${plan.gpu_count} x ${gpuModel} at site ${siteId}`);

// 2. Create. SDK 0.3.0 has no billing_catalog field yet, so add it to the request body.
const name = `example-gpu-${randomUUID().slice(0, 6)}`;
const request: CreateGpuVmRequest & { billing_catalog: unknown } = {
  name,
  site_id: siteId,
  plan_id: plan.plan_id,
  template_id: image.template_id,
  os_distro: image.os_distro,
  os_type: "linux",
  cpu: plan.cpu,
  ram_mb: plan.ram_mb,
  disk_gb: plan.disk_gb,
  gpu_count: plan.gpu_count,
  gpu_model: gpuModel,
  ssh_key_ids: process.env.IBEE_SSH_KEY_ID ? [process.env.IBEE_SSH_KEY_ID] : [],
  tags: ["example", "gpu"],
  billing_catalog: (plan as ComputePlan & { billing_catalog?: unknown }).billing_catalog,
};
const accepted = await client.gpuVms.create({ workspaceId, idempotencyKey: `create-${name}`, ...request });
console.log(`Creating ${name} (${accepted.vm_id})`);
await waitFor(accepted.operation_id);

const vm = await client.gpuVms.get({ workspaceId, vmId: accepted.vm_id });
console.log(`${vm.name} is ${vm.status}: ${vm.gpu_count} x ${vm.gpu_model}, public IP ${vm.public_ip}`);

// 3. Delete and release the automatic public IP. SDK 0.3.0 cannot send a delete body.
if (process.env.KEEP !== "1") {
  const response = await fetch(`${baseUrl}/compute/gpu-vms/${accepted.vm_id}?workspace_id=${workspaceId}`, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "X-Idempotency-Key": `delete-${accepted.vm_id}`,
    },
    body: JSON.stringify({ public_ip_action: "release" }),
  });
  if (!response.ok) throw new Error(`delete failed: ${response.status} ${await response.text()}`);
  await waitFor(((await response.json()) as { operation_id: string }).operation_id);
}
