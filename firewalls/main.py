"""Create a firewall group that allows HTTP and HTTPS, attach it to a VM, then remove it."""

import os

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
fw = client.firewalls
VM_ID = os.environ["IBEE_VM_ID"]

group = fw.create_firewall_group(name="web", description="HTTP and HTTPS from anywhere")
for port in (80, 443):
    fw.create_firewall_rule(
        group.firewall_group_id,
        direction="ingress",
        protocol="tcp",
        port_start=port,
        port_end=port,
        remote_targets=["0.0.0.0/0"],
        action="allow",
    )

group = fw.attach_firewall_group(group.firewall_group_id, vm_id=VM_ID)
for rule in group.rules:
    print(f"{rule.direction} {rule.protocol} {rule.port_start}-{rule.port_end} {rule.action}")

fw.detach_firewall_group(group.firewall_group_id, VM_ID)
fw.delete_firewall_group(group.firewall_group_id)
