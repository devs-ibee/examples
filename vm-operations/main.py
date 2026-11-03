"""Day-2 operations on a Cloud VM: metrics, events, and a resize."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
vms = client.cloud_vms
VM_ID = os.environ["IBEE_VM_ID"]


def wait(accepted):
    """Poll a VM operation until it finishes."""
    while True:
        op = vms.get_compute_operation(accepted.operation_id)
        if op.status in ("succeeded", "failed", "cancelled", "timed_out"):
            print(f"{op.action}: {op.status} {op.error_message or ''}")
            return op
        time.sleep(10)


vm = vms.get_cloud_vm(VM_ID)
print(f"{vm.name}: {vm.status}, {vm.cpu} vCPU, {vm.ram_mb} MB")

metrics = vms.get_cloud_vm_metrics(VM_ID)
print(f"CPU {metrics.cpu_percent}%, memory {metrics.memory_used_percent}%")
for event in vms.list_cloud_vm_events(VM_ID, limit=5):
    print(f"{event.created_at}  {event.event_type}  {event.message}")

# Resize CPU and memory. Stop the VM first; start it again afterwards.
wait(vms.stop_cloud_vm(VM_ID))
wait(vms.resize_cloud_vm(VM_ID, cpu=int(os.environ["IBEE_NEW_CPU"]), ram_mb=int(os.environ["IBEE_NEW_RAM_MB"])))
wait(vms.start_cloud_vm(VM_ID))
