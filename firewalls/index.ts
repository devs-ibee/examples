/**
 * Firewalls: a web-server firewall group attached to a VM.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx firewalls/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ADMIN_CIDR,
 *              IBEE_ENV=dev, KEEP=1
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const vmId = process.env.IBEE_VM_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});

const group = await client.firewalls.createGroup({ workspaceId, name: "web", description: "HTTP, HTTPS, and admin SSH" });
const firewallGroupId = group.firewall_group_id;

for (const port of [80, 443]) {
  await client.firewalls.createRule({
    workspaceId,
    firewallGroupId,
    description: `Allow TCP ${port}`,
    direction: "ingress",
    protocol: "tcp",
    portStart: port,
    portEnd: port,
    remoteTargets: ["0.0.0.0/0"],
    action: "allow",
  });
}

if (process.env.IBEE_ADMIN_CIDR) {
  await client.firewalls.createRule({
    workspaceId,
    firewallGroupId,
    description: "Admin SSH",
    direction: "ingress",
    protocol: "tcp",
    portStart: 22,
    portEnd: 22,
    remoteTargets: [process.env.IBEE_ADMIN_CIDR],
    action: "allow",
  });
}

// Attach after the rules exist.
await client.firewalls.attach({ workspaceId, firewallGroupId, vmId });
console.log(`Firewall group ${firewallGroupId} protects ${vmId}`);

if (process.env.KEEP !== "1") {
  await client.firewalls.detach({ workspaceId, firewallGroupId, vmId });
  await client.firewalls.deleteGroup({ workspaceId, firewallGroupId });
  console.log(`Deleted firewall group ${firewallGroupId}`);
}
