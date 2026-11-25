// Create a regional HTTP load balancer in front of two VMs, change it, and delete it.
import { Ibee, type LoadBalancerSpec } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const lbs = ibee.loadBalancers;
const [region] = await lbs.listLoadBalancerRegions();

/** The whole specification: create sends it, and every update sends it again. */
const spec = (healthPath: string): LoadBalancerSpec => ({
  name: "example-web",
  region_id: region.id as string,
  traffic_type: "http",
  // Listeners are the ports it answers on; each sends traffic to a target group.
  listeners: [{ name: "http", protocol: "HTTP", port: 80, target_group: "web" }],
  // Targets are VMs with their own public IP, by ID. Private addresses ({ kind: "ip" }) only work
  // in a region whose capabilities.private_targets is true, and then also need vpc_id.
  target_groups: [
    {
      name: "web",
      protocol: "HTTP",
      targets: process.env.IBEE_BACKEND_VM_IDS!.split(",").map((resource_id) => ({ kind: "vm", resource_id, port: 80 })),
      // Leave unhealthy_threshold out: the service uses 1 for HTTP checks and 3 for TCP.
      health_check: { protocol: "HTTP", path: healthPath },
    },
  ],
});

/** Poll a load balancer operation until it finishes. */
async function wait({ id }: { id: string }) {
  for (;;) {
    const op = await lbs.getLoadBalancerOperation({ operation_id: id });
    if (op.completed_at) return console.log(`${op.kind}: ${op.status} ${op.reason ?? ""}`);
    await new Promise((resolve) => setTimeout(resolve, 10_000));
  }
}

const accepted = await lbs.createLoadBalancer({ body: spec("/") });
await wait(accepted);

const lb = await lbs.getLoadBalancer({ load_balancer_id: accepted.lb_id });
// The public address clients connect to (point an A record at it for your own domain).
const address = lb.conditions.addresses?.[0] ?? "-";
console.log(`${lb.name} in ${region.name} is ${lb.observed_state} at ${address}, version ${lb.version}`);

// An update replaces the whole specification and sends the version it was read at.
await wait(await lbs.updateLoadBalancer({ load_balancer_id: lb.id, version: lb.version, specification: spec("/healthz") }));

await wait(await lbs.deleteLoadBalancer({ load_balancer_id: lb.id }));
