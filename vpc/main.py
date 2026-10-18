"""Create a VPC and a subnet, attach a VM, then remove all three."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
net = client.vpcs
VM_ID = os.environ["IBEE_VM_ID"]

# The API picks free address ranges when you give no CIDR.
vpc = net.create_vpc(name="example-network", site_id=os.environ["IBEE_SITE_ID"], create_default_subnet=False)
while (vpc := net.get_vpc(vpc.vpc_id)).status != "available":
    time.sleep(5)
print(f"VPC {vpc.vpc_id} ({vpc.cidr}) is {vpc.status}")

subnet = net.create_vpc_subnet(vpc.vpc_id, name="apps")
while (subnet := net.get_vpc_subnet(vpc.vpc_id, subnet.subnet_id)).status != "available":
    time.sleep(5)
print(f"Subnet {subnet.subnet_id} ({subnet.cidr}), gateway {subnet.gateway}")

node = net.attach_vpc_node(vpc.vpc_id, vm_id=VM_ID, subnet_id=subnet.subnet_id)
print(f"VM {VM_ID} has private IP {node.private_ip}")

net.detach_vpc_node(vpc.vpc_id, VM_ID)
net.delete_vpc_subnet(vpc.vpc_id, subnet.subnet_id)
net.delete_vpc(vpc.vpc_id)
