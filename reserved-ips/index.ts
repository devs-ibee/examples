/**
 * Reserved IPs: reserve, attach, move, detach, and release a public address.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx reserved-ips/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_SITE_ID, IBEE_VM_ID, IBEE_VPC_ID,
 *              IBEE_SUBNET_ID, optional IBEE_NEW_VM_ID, IBEE_ENV=dev, KEEP=1
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const ips = client.reservedIps;
const placement = { vpcId: process.env.IBEE_VPC_ID, subnetId: process.env.IBEE_SUBNET_ID };

// 1. Reserve an address.
const ip = await ips.reserve({ workspaceId, siteId: process.env.IBEE_SITE_ID!, label: "example-web" });
const reservedIpId = ip.public_ip_id;
console.log(`Reserved ${ip.address} (${reservedIpId})`);

// 2. Attach it to a VM.
await ips.attach({ workspaceId, reservedIpId, vmId: process.env.IBEE_VM_ID!, ...placement });

// 3. Move it to a replacement VM without changing the address.
if (process.env.IBEE_NEW_VM_ID) {
  await ips.move({ workspaceId, reservedIpId, vmId: process.env.IBEE_NEW_VM_ID, ...placement });
}
const current = await ips.get({ workspaceId, reservedIpId });
console.log(`${current.address}: ${current.status}, attached to ${current.attached_resource_id}`);

// 4. Detach and release.
if (process.env.KEEP !== "1") {
  await ips.detach({ workspaceId, reservedIpId });
  await ips.release({ workspaceId, reservedIpId });
  console.log(`Released ${ip.address}`);
}
