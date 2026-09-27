/**
 * Load Balancers: an L7 HTTP balancer with path routing and an L4 TCP balancer.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx load-balancers/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BACKEND_IPS (comma-separated),
 *              optional IBEE_ENV=dev, KEEP=1
 */
import { Ibee, IbeeEnvironment, type LoadBalancerBackend } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const backendIps = (process.env.IBEE_BACKEND_IPS ?? "").split(",").map((ip) => ip.trim()).filter(Boolean);
if (backendIps.length === 0) throw new Error("Set IBEE_BACKEND_IPS to the backend VM addresses");
const backends = (port: number): LoadBalancerBackend[] => backendIps.map((target) => ({ type: "ip", target, port }));

async function waitUntilActive(loadBalancerId: string) {
  for (let attempt = 0; attempt < 90; attempt++) {
    const status = await client.loadBalancers.getStatus({ workspaceId, loadBalancerId });
    if (status.status === "active") return status;
    if (status.status === "failed") throw new Error(`load balancer ${loadBalancerId} failed: ${status.error_message}`);
    await sleep(10_000);
  }
  throw new Error(`load balancer ${loadBalancerId} did not become active`);
}

// 1. L7: web traffic on port 80, /api to port 8080.
const web = await client.loadBalancers.createL7({
  workspaceId,
  name: "example-web",
  protocol: "http",
  backends: backends(80),
  routing: { algorithm: "round_robin" },
  rules: [{ priority: 10, path_prefix: "/api", backends: backends(8080) }],
});

// 2. L4: raw TCP, for example a database or a custom protocol.
const tcp = await client.loadBalancers.createL4({ workspaceId, name: "example-postgres", protocol: "tcp", backends: backends(5432) });

for (const lb of [web, tcp]) {
  const ready = await waitUntilActive(lb.lb_id);
  console.log(`${lb.name} (${lb.layer}) is active at ${ready.endpoint_url}`);
}

if (process.env.KEEP !== "1") {
  for (const lb of [web, tcp]) {
    await client.loadBalancers.delete({ workspaceId, loadBalancerId: lb.lb_id });
    console.log(`Deleted ${lb.name}`);
  }
}
