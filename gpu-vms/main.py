"""GPU VM lifecycle: create from a GPU plan, wait, then delete.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (vm.read, vm.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_ENV           "dev" to use the development API (optional)
  IBEE_SITE_ID       site to use (optional, defaults to the first site with GPU plans)
  IBEE_GPU_MODEL     GPU model, when the plan does not report one (optional)
  IBEE_SSH_KEY_ID    SSH key to inject (optional)
  KEEP               set to 1 to keep the VM
"""

import os
import time
import uuid

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)


def wait_for(operation_id, timeout_seconds=3600):
    deadline = time.monotonic() + timeout_seconds
    while True:
        op = client.cloud_vms.get_compute_operation(operation_id=operation_id, workspace_id=WORKSPACE_ID)
        if op.status in {"succeeded", "failed", "cancelled", "timed_out"}:
            break
        if time.monotonic() > deadline:
            raise TimeoutError(f"operation {operation_id} is still {op.status}")
        print(f"  {op.action}: {op.status} {op.current_step or ''}")
        time.sleep(15)
    if op.status != "succeeded":
        raise RuntimeError(f"{op.action} {op.status}: {op.error_code} {op.error_message}")
    print(f"  {op.action}: succeeded")


def priced_gpu_plans(site_id):
    plans = client.compute_catalog.list_compute_plans(workspace_id=WORKSPACE_ID, vm_type="gpu", site_id=site_id).plans
    return [p for p in plans if p.selectable and p.pricing_status == "priced" and p.gpu_count > 0]


# 1. Find a site that offers GPU plans.
sites = [os.environ["IBEE_SITE_ID"]] if os.getenv("IBEE_SITE_ID") else [
    s.site_id for s in client.compute_catalog.list_compute_sites(workspace_id=WORKSPACE_ID).sites
]
site_id, plans = next(((site, priced_gpu_plans(site)) for site in sites if priced_gpu_plans(site)), (None, []))
if not plans:
    raise SystemExit("No priced GPU plans are available to this workspace. Contact support for GPU access.")

plan = min(plans, key=lambda p: p.hourly_price_minor or 0)
gpu_model = plan.gpu_model or os.getenv("IBEE_GPU_MODEL")
if not gpu_model:
    raise SystemExit(f"Plan {plan.plan_id} does not report its GPU model; set IBEE_GPU_MODEL")
images = client.compute_catalog.list_compute_images(workspace_id=WORKSPACE_ID, vm_type="gpu", site_id=site_id).images
image = next((i for i in images if i.gpu_compatible and i.os_distro == "ubuntu"), images[0])
print(f"{plan.name}: {plan.gpu_count} x {gpu_model}, {plan.cpu} vCPU, {plan.ram_mb} MB RAM at site {site_id}")

# 2. Create. Pass the plan's billing_catalog unchanged (SDK 0.3.0 has no named argument for it).
name = f"example-gpu-{uuid.uuid4().hex[:6]}"
accepted = client.gpu_vms.create_gpu_vm(
    workspace_id=WORKSPACE_ID,
    idempotency_key=f"create-{name}",
    name=name,
    site_id=site_id,
    plan_id=plan.plan_id,
    template_id=image.template_id,
    os_distro=image.os_distro,
    os_type="linux",
    cpu=plan.cpu,
    ram_mb=plan.ram_mb,
    disk_gb=plan.disk_gb,
    gpu_count=plan.gpu_count,
    gpu_model=gpu_model,
    ssh_key_ids=[os.environ["IBEE_SSH_KEY_ID"]] if os.getenv("IBEE_SSH_KEY_ID") else [],
    tags=["example", "gpu"],
    request_options={"additional_body_parameters": {"billing_catalog": getattr(plan, "billing_catalog", None)}},
)
print(f"Creating {name} ({accepted.vm_id})")
wait_for(accepted.operation_id)

vm = client.gpu_vms.get_gpu_vm(vm_id=accepted.vm_id, workspace_id=WORKSPACE_ID)
print(f"{vm.name} is {vm.status}: {vm.gpu_count} x {vm.gpu_model}, public IP {vm.public_ip}")
print(f"Connect with: ssh ubuntu@{vm.public_ip}   then run: nvidia-smi")

# 3. Delete and release the automatic public IP.
if os.getenv("KEEP") != "1":
    deleted = client.gpu_vms.delete_gpu_vm(
        vm_id=accepted.vm_id,
        workspace_id=WORKSPACE_ID,
        idempotency_key=f"delete-{accepted.vm_id}",
        request_options={"additional_body_parameters": {"public_ip_action": "release"}},
    )
    wait_for(deleted.operation_id)
