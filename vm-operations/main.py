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

# Resize to another plan: send its exact size and its billing_catalog with one of its
# billing_options merged in, as on create. Stop the VM first; start it again afterwards.
plans = client.compute_catalog.list_compute_plans(vm_type="cloud", site_id=os.environ["IBEE_SITE_ID"]).plans
plan = next(p for p in plans if p.plan_id == os.environ["IBEE_NEW_PLAN_ID"])
hourly = next(o for o in plan.billing_catalog["billing_options"] if o["billing_interval"] == "HOURLY")

wait(vms.stop_cloud_vm(VM_ID))
wait(vms.resize_cloud_vm(
    VM_ID,
    cpu=plan.cpu,
    ram_mb=plan.ram_mb,
    disk_gb=plan.disk_gb,
    billing_catalog={**plan.billing_catalog, **hourly},
))
wait(vms.start_cloud_vm(VM_ID))
