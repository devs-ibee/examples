"""Firewalls: a web-server firewall group attached to a VM.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (firewall.read, firewall.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_VM_ID         VM to protect
  IBEE_ADMIN_CIDR    network allowed to use SSH, for example 198.51.100.7/32 (optional)
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the firewall group attached
"""

import os

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
VM_ID = os.environ["IBEE_VM_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
fw = client.firewalls

group = fw.create_firewall_group(workspace_id=WORKSPACE_ID, name="web", description="HTTP, HTTPS, and admin SSH")
group_id = group.firewall_group_id

# Public web traffic.
for port in (80, 443):
    fw.create_firewall_rule(
        firewall_group_id=group_id,
        workspace_id=WORKSPACE_ID,
        description=f"Allow TCP {port}",
        direction="ingress",
        protocol="tcp",
        port_start=port,
        port_end=port,
        remote_targets=["0.0.0.0/0"],
        action="allow",
    )

# SSH only from your own network.
if os.getenv("IBEE_ADMIN_CIDR"):
    group = fw.create_firewall_rule(
        firewall_group_id=group_id,
        workspace_id=WORKSPACE_ID,
        description="Admin SSH",
        direction="ingress",
        protocol="tcp",
        port_start=22,
        port_end=22,
        remote_targets=[os.environ["IBEE_ADMIN_CIDR"]],
        action="allow",
    )

group = fw.get_firewall_group(firewall_group_id=group_id, workspace_id=WORKSPACE_ID)
for rule in group.rules:
    print(f"  {rule.direction} {rule.protocol} {rule.port_start}-{rule.port_end} from {rule.remote_targets}: {rule.action}")

# Attach after the rules exist.
fw.attach_firewall_group(firewall_group_id=group_id, workspace_id=WORKSPACE_ID, vm_id=VM_ID)
print("Attachments:", fw.list_firewall_group_attachments(firewall_group_id=group_id, workspace_id=WORKSPACE_ID))

if os.getenv("KEEP") != "1":
    fw.detach_firewall_group(firewall_group_id=group_id, vm_id=VM_ID, workspace_id=WORKSPACE_ID)
    fw.delete_firewall_group(firewall_group_id=group_id, workspace_id=WORKSPACE_ID)
    print(f"Deleted firewall group {group_id}")
