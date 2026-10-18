"""Create a Cloud VM, read it, and delete it."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV


def wait(accepted):
    """Poll a VM operation until it finishes."""
    while True:
        op = client.cloud_vms.get_compute_operation(accepted.operation_id)
        if op.status in ("succeeded", "failed", "cancelled", "timed_out"):
            print(f"{op.action}: {op.status} {op.error_message or ''}")
            return op
        time.sleep(10)


accepted = client.cloud_vms.create_cloud_vm(
    name="example-vm",
    site_id=os.environ["IBEE_SITE_ID"],
    plan_id=os.environ["IBEE_PLAN_ID"],
    template_id=os.environ["IBEE_TEMPLATE_ID"],
    billing_term="HOURLY",
)
wait(accepted)

vm = client.cloud_vms.get_cloud_vm(accepted.vm_id)
print(f"{vm.name} is {vm.status}, public IP {vm.public_ip}")

wait(client.cloud_vms.delete_cloud_vm(accepted.vm_id, public_ip_action="release"))
