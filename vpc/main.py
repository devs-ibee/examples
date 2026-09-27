"""Private networking: a NAT-gateway VPC, a subnet, a VM attachment, and port forwarding.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (network.read, network.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_VM_ID         VM to attach to the VPC
  IBEE_SITE_ID       networking site (optional, defaults to the first available site)
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the network
"""

import os
import time

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
VM_ID = os.environ["IBEE_VM_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
net = client.vpcs


def wait_until_available(read, what, timeout_seconds=600):
    deadline = time.monotonic() + timeout_seconds
    while True:
        resource = read()
        if resource.status == "available":
            return resource
        if resource.status == "error" or time.monotonic() > deadline:
            raise RuntimeError(f"{what} is {resource.status}: {resource.error_message}")
        time.sleep(5)


site_id = os.getenv("IBEE_SITE_ID") or next(
    s.site_id for s in net.list_networking_sites(workspace_id=WORKSPACE_ID) if s.available
)

# 1. A VPC whose managed NAT gateway is created with it.
vpc = net.create_vpc(
    workspace_id=WORKSPACE_ID,
    name="example-network",
    site_id=site_id,
    cidr="10.44.0.0/22",
    auto_cidr=False,
    create_default_subnet=False,
    connectivity_type="nat_gateway",
)
vpc = wait_until_available(lambda: net.get_vpc(vpc_id=vpc.vpc_id, workspace_id=WORKSPACE_ID), "VPC")
print(f"VPC {vpc.vpc_id} ({vpc.cidr}) is available")

# 2. A subnet for application VMs.
subnet = net.create_vpc_subnet(
    vpc_id=vpc.vpc_id, workspace_id=WORKSPACE_ID, name="applications", cidr="10.44.0.0/24", auto_cidr=False
)
subnet = wait_until_available(
    lambda: net.get_vpc_subnet(vpc_id=vpc.vpc_id, subnet_id=subnet.subnet_id, workspace_id=WORKSPACE_ID), "subnet"
)
print(f"Subnet {subnet.subnet_id} ({subnet.cidr}), gateway {subnet.gateway}")

# 3. Attach the VM with outbound internet through NAT.
allocation = net.attach_vpc_node(
    vpc_id=vpc.vpc_id, workspace_id=WORKSPACE_ID, vm_id=VM_ID, subnet_id=subnet.subnet_id, connectivity="nat"
)
print(f"VM {VM_ID} has private IP {allocation.private_ip}")

# 4. Forward NAT port 2222 to SSH on the VM.
nat = net.list_nat_gateways(vpc_id=vpc.vpc_id, workspace_id=WORKSPACE_ID)[0]
rule = net.create_nat_port_forwarding_rule(
    vpc_id=vpc.vpc_id,
    nat_gateway_id=nat.nat_gateway_id,
    workspace_id=WORKSPACE_ID,
    name="ssh",
    protocol="tcp",
    external_port=2222,
    internal_ip=allocation.private_ip,
    internal_port=22,
)
print(f"Connect with: ssh -p 2222 <user>@{nat.public_ip}")

# 5. Clean up in reverse order. Deleting the VPC also removes its NAT gateway.
if os.getenv("KEEP") != "1":
    net.delete_nat_port_forwarding_rule(
        vpc_id=vpc.vpc_id,
        nat_gateway_id=nat.nat_gateway_id,
        port_forwarding_rule_id=rule.port_forward_rule_id,
        workspace_id=WORKSPACE_ID,
    )
    net.detach_vpc_node(vpc_id=vpc.vpc_id, vm_id=VM_ID, workspace_id=WORKSPACE_ID)
    net.delete_vpc_subnet(vpc_id=vpc.vpc_id, subnet_id=subnet.subnet_id, workspace_id=WORKSPACE_ID)
    net.delete_vpc(vpc_id=vpc.vpc_id, workspace_id=WORKSPACE_ID)
    print("Removed the forwarding rule, attachment, subnet, and VPC")
