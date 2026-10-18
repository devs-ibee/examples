"""Create a GPU VM, read it, and delete it."""

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
        time.sleep(15)


accepted = client.gpu_vms.create_gpu_vm(
    name="example-gpu",
    site_id=os.environ["IBEE_SITE_ID"],
    plan_id=os.environ["IBEE_GPU_PLAN_ID"],
    template_id=os.environ["IBEE_GPU_TEMPLATE_ID"],
    billing_term="HOURLY",
)
wait(accepted)

vm = client.gpu_vms.get_gpu_vm(accepted.vm_id)
print(f"{vm.name} is {vm.status}: {vm.gpu_count} x {vm.gpu_model}, public IP {vm.public_ip}")

wait(client.gpu_vms.delete_gpu_vm(accepted.vm_id, public_ip_action="release"))
