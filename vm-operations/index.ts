/**
 * Day-2 Cloud VM operations: metrics, events, resize, SSH access, and console.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx vm-operations/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev,
 *              RESIZE=1, IBEE_SSH_PUBLIC_KEY
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const vmId = process.env.IBEE_VM_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const vms = client.cloudVms;
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

// 1. Observability.
const vm = await vms.get({ workspaceId, vmId });
console.log(`${vm.name}: ${vm.status}, ${vm.cpu} vCPU, ${vm.ram_mb} MB RAM`);
console.log("Current metrics:", await vms.getMetrics({ workspaceId, vmId }));
const series = await vms.getMetricsTimeseries({ workspaceId, vmId, range: "1h" });
console.log(`Metric series at ${series.resolution} resolution: ${Object.keys(series.series).join(", ")}`);
const month = new Date().toISOString().slice(0, 7);
const bandwidth = await vms.getBandwidth({ workspaceId, vmId, month });
console.log(`Bandwidth in ${month}: received ${bandwidth.rx_bytes} bytes, sent ${bandwidth.tx_bytes} bytes`);
for (const event of await vms.listEvents({ workspaceId, vmId, limit: 5 })) {
  console.log(`Event ${event.created_at}: ${event.event_type}: ${event.message}`);
}

// 2. Resize precheck to the next larger priced plan.
const { plans } = await client.computeCatalog.listPlans({ workspaceId, vmType: "cloud" });
const current = [vm.cpu ?? 0, vm.ram_mb ?? 0];
const target = plans
  .filter((p) => p.selectable && p.pricing_status === "priced")
  .filter((p) => p.cpu > current[0] || (p.cpu === current[0] && p.ram_mb > current[1]))
  .sort((a, b) => a.cpu - b.cpu || a.ram_mb - b.ram_mb)[0];
if (target) {
  const check = await vms.precheckResize({ workspaceId, vmId, request: { cpu: target.cpu, ram_mb: target.ram_mb } });
  console.log(`Resize to ${target.cpu} vCPU / ${target.ram_mb} MB: ${check.decision}, requires stop: ${check.requires_stop}`);
  check.reasons.forEach((reason) => console.log("  reason:", reason));
  check.warnings.forEach((warning) => console.log("  warning:", warning));

  // 3. Apply the resize only when asked to, and only when the precheck allows it.
  if (process.env.RESIZE === "1" && check.decision !== "blocked") {
    if (check.requires_stop) await waitFor((await vms.stop({ workspaceId, vmId })).operation_id);
    await waitFor((await vms.resizePlan({ workspaceId, vmId, request: { cpu: target.cpu, ram_mb: target.ram_mb } })).operation_id);
    if (check.requires_stop) await waitFor((await vms.start({ workspaceId, vmId })).operation_id);
  }
}

// 4. Add an SSH public key to the admin user.
if (process.env.IBEE_SSH_PUBLIC_KEY) {
  const accepted = await vms.updateAccess({
    workspaceId,
    vmId,
    request: { ssh_key_mode: "add", ssh_keys: [process.env.IBEE_SSH_PUBLIC_KEY] },
  });
  await waitFor(accepted.operation_id);
}

// 5. A short-lived browser console. The URL grants access: do not log or share it.
const session = await client.vmConsole.createSession({ workspaceId, vmId, vmType: "cloud" });
console.log(`Console session ${session.session_id} expires in ${session.token_expires_in_seconds} seconds:`);
console.log(session.connect_url);
