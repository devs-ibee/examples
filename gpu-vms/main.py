"""Create a GPU VM, read it, and delete it."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
SITE_ID = os.environ["IBEE_SITE_ID"]


def wait(accepted):
    """Poll a VM operation until it finishes."""
    while True:
        op = client.cloud_vms.get_compute_operation(accepted.operation_id)
        if op.status in ("succeeded", "failed", "cancelled", "timed_out"):
            print(f"{op.action}: {op.status} {op.error_message or ''}")
            return op
        time.sleep(15)


# The request carries the plan's size, GPUs and price and the image's OS, so read both first.
plans = client.compute_catalog.list_compute_plans(vm_type="gpu", site_id=SITE_ID).plans
plan = next(p for p in plans if p.plan_id == os.environ["IBEE_GPU_PLAN_ID"])
images = client.compute_catalog.list_compute_images(vm_type="gpu", site_id=SITE_ID).images
image = next(i for i in images if i.template_id == os.environ["IBEE_GPU_TEMPLATE_ID"])

# billing_catalog is the plan's billing_catalog with one of its billing_options merged in.
hourly = next(o for o in plan.billing_catalog["billing_options"] if o["billing_interval"] == "HOURLY")

accepted = client.gpu_vms.create_gpu_vm(
    name="example-gpu",
    site_id=SITE_ID,
    plan_id=plan.plan_id,
    cpu=plan.cpu,
    ram_mb=plan.ram_mb,
    disk_gb=plan.disk_gb,
    gpu_count=plan.gpu_count,
    gpu_model=plan.gpu_model,
    template_id=image.template_id,
    os_type="linux",
    os_distro=image.os_distro,
    billing_catalog={**plan.billing_catalog, **hourly},
)
wait(accepted)

vm = client.gpu_vms.get_gpu_vm(accepted.vm_id)
print(f"{vm.name} is {vm.status}: {vm.gpu_count} x {vm.gpu_model}, public IP {vm.public_ip}")

wait(client.gpu_vms.delete_gpu_vm(accepted.vm_id, public_ip_action="release"))
