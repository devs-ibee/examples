// Create a firewall group that allows HTTP and HTTPS, attach it to a VM, then remove it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const fw = ibee.firewalls;
const vm_id = process.env.IBEE_VM_ID!;

const { firewall_group_id } = await fw.createFirewallGroup({ name: "web", description: "HTTP and HTTPS from anywhere" });
for (const port of [80, 443]) {
  await fw.createFirewallRule({
    firewall_group_id,
    body: {
      direction: "ingress",
      protocol: "tcp",
      port_start: port,
      port_end: port,
      remote_targets: ["0.0.0.0/0"],
      action: "allow",
    },
  });
}

const group = await fw.attachFirewallGroup({ firewall_group_id, vm_id });
for (const rule of group.rules) {
  console.log(`${rule.direction} ${rule.protocol} ${rule.port_start}-${rule.port_end} ${rule.action}`);
}

await fw.detachFirewallGroup({ firewall_group_id, vm_id });
await fw.deleteFirewallGroup({ firewall_group_id });
