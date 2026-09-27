"""Reserved IPs: reserve, attach, move, detach, and release a public address.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (network.read, network.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_SITE_ID       site to reserve the address at
  IBEE_VM_ID         VM to attach the address to
  IBEE_VPC_ID        VPC the VM is attached to
  IBEE_SUBNET_ID     subnet the VM is attached to
  IBEE_NEW_VM_ID     another VM in the same subnet to move the address to (optional)
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the address
"""

import os

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
ips = client.reserved_ips
placement = {"vpc_id": os.getenv("IBEE_VPC_ID"), "subnet_id": os.getenv("IBEE_SUBNET_ID")}
placement = {key: value for key, value in placement.items() if value}

# 1. Reserve an address.
ip = ips.reserve_ip(workspace_id=WORKSPACE_ID, site_id=os.environ["IBEE_SITE_ID"], label="example-web")
print(f"Reserved {ip.address} ({ip.public_ip_id})")

# 2. Attach it to a VM.
ips.attach_reserved_ip(reserved_ip_id=ip.public_ip_id, workspace_id=WORKSPACE_ID, vm_id=os.environ["IBEE_VM_ID"], **placement)
print(f"{ip.address} now routes to {os.environ['IBEE_VM_ID']}")

# 3. Move it to a replacement VM without changing the address.
if os.getenv("IBEE_NEW_VM_ID"):
    ips.move_reserved_ip(
        reserved_ip_id=ip.public_ip_id, workspace_id=WORKSPACE_ID, vm_id=os.environ["IBEE_NEW_VM_ID"], **placement
    )
    print(f"{ip.address} moved to {os.environ['IBEE_NEW_VM_ID']}")

current = ips.get_reserved_ip(reserved_ip_id=ip.public_ip_id, workspace_id=WORKSPACE_ID)
print(f"{current.address}: {current.status}, attached to {current.attached_resource_id}")

# 4. Detach and release. Released addresses return to the pool.
if os.getenv("KEEP") != "1":
    ips.detach_reserved_ip(reserved_ip_id=ip.public_ip_id, workspace_id=WORKSPACE_ID)
    ips.release_reserved_ip(reserved_ip_id=ip.public_ip_id, workspace_id=WORKSPACE_ID)
    print(f"Released {ip.address}")
