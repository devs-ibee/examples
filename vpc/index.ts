/**
 * Private networking: a NAT-gateway VPC, a subnet, a VM attachment, and port forwarding.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx vpc/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_SITE_ID,
 *              IBEE_ENV=dev, KEEP=1
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const vmId = process.env.IBEE_VM_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function untilAvailable<T extends { status: string }>(read: () => Promise<T>, what: string): Promise<T> {
  for (let attempt = 0; attempt < 120; attempt++) {
    const resource = await read();
    if (resource.status === "available") return resource;
    if (resource.status === "error") throw new Error(`${what} failed`);
    await sleep(5_000);
  }
  throw new Error(`${what} did not become available`);
}

const siteId =
  process.env.IBEE_SITE_ID ?? (await client.vpcs.listSites({ workspaceId })).find((site) => site.available)!.site_id;

// 1. A VPC whose managed NAT gateway is created with it.
const created = await client.vpcs.create({
  workspaceId,
  name: "example-network",
  siteId,
  cidr: "10.44.0.0/22",
  autoCidr: false,
  createDefaultSubnet: false,
  connectivityType: "nat_gateway",
});
const vpcId = created.vpc_id;
await untilAvailable(() => client.vpcs.get({ workspaceId, vpcId }), "VPC");

// 2. A subnet for application VMs.
const subnet = await client.vpcs.createSubnet({
  workspaceId,
  vpcId,
  name: "applications",
  cidr: "10.44.0.0/24",
  autoCidr: false,
});
await untilAvailable(() => client.vpcs.getSubnet({ workspaceId, vpcId, subnetId: subnet.subnet_id }), "subnet");

// 3. Attach the VM with outbound internet through NAT.
const allocation = await client.vpcs.attachNode({
  workspaceId,
  vpcId,
  vmId,
  subnetId: subnet.subnet_id,
  connectivity: "nat",
});
console.log(`VM ${vmId} has private IP ${allocation.private_ip}`);

// 4. Forward NAT port 2222 to SSH on the VM.
const [nat] = await client.vpcs.listNatGateways({ workspaceId, vpcId });
const rule = await client.vpcs.createPortForwardingRule({
  workspaceId,
  vpcId,
  natGatewayId: nat.nat_gateway_id,
  name: "ssh",
  protocol: "tcp",
  externalPort: 2222,
  internalIp: allocation.private_ip!,
  internalPort: 22,
});
// The API returns the rule ID as port_forward_rule_id; SDK 0.3.0's type omits it.
const ruleId = (rule as typeof rule & { port_forward_rule_id: string }).port_forward_rule_id;
console.log(`Connect with: ssh -p 2222 <user>@${nat.public_ip}`);

// 5. Clean up in reverse order. Deleting the VPC also removes its NAT gateway.
if (process.env.KEEP !== "1") {
  await client.vpcs.deletePortForwardingRule({
    workspaceId,
    vpcId,
    natGatewayId: nat.nat_gateway_id,
    portForwardingRuleId: ruleId,
  });
  await client.vpcs.detachNode({ workspaceId, vpcId, vmId });
  await client.vpcs.deleteSubnet({ workspaceId, vpcId, subnetId: subnet.subnet_id });
  await client.vpcs.delete({ workspaceId, vpcId });
  console.log("Removed the forwarding rule, attachment, subnet, and VPC");
}
