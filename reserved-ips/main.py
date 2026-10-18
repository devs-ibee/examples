"""Reserve a public IP, attach it to a VM, detach it, and release it."""

import os

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
ips = client.reserved_ips

ip = ips.reserve_ip(site_id=os.environ["IBEE_SITE_ID"], label="example-web")
print(f"Reserved {ip.address} ({ip.public_ip_id})")

ips.attach_reserved_ip(ip.public_ip_id, vm_id=os.environ["IBEE_VM_ID"])
ip = ips.get_reserved_ip(ip.public_ip_id)
print(f"{ip.address} is {ip.status}, attached to {ip.attached_resource_id}")

ips.detach_reserved_ip(ip.public_ip_id)
ips.release_reserved_ip(ip.public_ip_id)
