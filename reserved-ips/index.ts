// Reserve a public IP, attach it to a VM, detach it, and release it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const ips = ibee.reservedIps;

const reserved = await ips.reserveIp({ site_id: process.env.IBEE_SITE_ID!, label: "example-web" });
const reserved_ip_id = reserved.public_ip_id;
console.log(`Reserved ${reserved.address} (${reserved_ip_id})`);

await ips.attachReservedIp({ reserved_ip_id, body: { vm_id: process.env.IBEE_VM_ID! } });
const ip = await ips.getReservedIp({ reserved_ip_id });
console.log(`${ip.address} is ${ip.status}, attached to ${ip.attached_resource_id}`);

await ips.detachReservedIp({ reserved_ip_id });
await ips.releaseReservedIp({ reserved_ip_id });
