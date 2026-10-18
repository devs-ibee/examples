// Create a VPC and a subnet, attach a VM, then remove all three.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const net = ibee.vpcs;
const vm_id = process.env.IBEE_VM_ID!;
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// The API picks free address ranges when you give no CIDR.
const { vpc_id } = await net.createVpc({
  name: "example-network",
  site_id: process.env.IBEE_SITE_ID!,
  create_default_subnet: false,
});
while ((await net.getVpc({ vpc_id })).status !== "available") await sleep(5_000);
console.log(`VPC ${vpc_id} is available`);

const { subnet_id } = await net.createVpcSubnet({ vpc_id, name: "apps" });
while ((await net.getVpcSubnet({ vpc_id, subnet_id })).status !== "available") await sleep(5_000);
console.log(`Subnet ${subnet_id} is available`);

const node = await net.attachVpcNode({ vpc_id, vm_id, subnet_id });
console.log(`VM ${vm_id} has private IP ${node.private_ip}`);

await net.detachVpcNode({ vpc_id, vm_id });
await net.deleteVpcSubnet({ vpc_id, subnet_id });
await net.deleteVpc({ vpc_id });
