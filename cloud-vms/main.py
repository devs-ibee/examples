"""Cloud VM lifecycle: create, wait, stop, start, and delete.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (vm.read, vm.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_ENV           "dev" to use the development API (optional)
  IBEE_SITE_ID       site to place the VM in (optional, defaults to the first site)
  IBEE_SSH_KEY_ID    SSH key to inject (optional)
  KEEP               set to 1 to keep the VM instead of deleting it
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

TERMINAL = {"succeeded", "failed", "cancelled", "timed_out"}


def wait_for(operation_id, timeout_seconds=1800):
    """Poll an asynchronous VM operation until it finishes."""
    deadline = time.monotonic() + timeout_seconds
    while True:
        op = client.cloud_vms.get_compute_operation(operation_id=operation_id, workspace_id=WORKSPACE_ID)
        if op.status in TERMINAL:
            break
        if time.monotonic() > deadline:
            raise TimeoutError(f"operation {operation_id} is still {op.status}")
        print(f"  {op.action}: {op.status} {op.current_step or ''}")
        time.sleep(10)
    if op.status != "succeeded":
        raise RuntimeError(f"{op.action} {op.status}: {op.error_code} {op.error_message}")
    print(f"  {op.action}: succeeded")
    return op


# 1. Site, plan, and image, chosen the way the portal's deploy page does.
site_id = os.getenv("IBEE_SITE_ID") or client.compute_catalog.list_compute_sites(workspace_id=WORKSPACE_ID).sites[0].site_id
plans = client.compute_catalog.list_compute_plans(workspace_id=WORKSPACE_ID, vm_type="cloud", site_id=site_id).plans
plan = min(
    (p for p in plans if p.selectable and p.pricing_status == "priced"),
    key=lambda p: p.hourly_price_minor or 0,
)
images = client.compute_catalog.list_compute_images(workspace_id=WORKSPACE_ID, vm_type="cloud", site_id=site_id).images
image = next((i for i in images if i.os_distro == "ubuntu"), images[0])

# The plan carries a billing_catalog object that must be sent back unchanged.
billing_catalog = getattr(plan, "billing_catalog", None)
if billing_catalog is None:
    raise SystemExit(f"plan {plan.plan_id} has no billing_catalog; choose another plan")
print(f"Plan {plan.name} ({plan.cpu} vCPU, {plan.ram_mb} MB RAM) with image {image.name} at site {site_id}")

# 2. Create the VM. SDK 0.3.0 has no billing_catalog argument yet, so pass it as an extra body field.
name = f"example-vm-{uuid.uuid4().hex[:6]}"
ssh_key_ids = [os.environ["IBEE_SSH_KEY_ID"]] if os.getenv("IBEE_SSH_KEY_ID") else []
accepted = client.cloud_vms.create_cloud_vm(
    workspace_id=WORKSPACE_ID,
    idempotency_key=f"create-{name}",  # reuse the same key if you retry this request
    name=name,
    site_id=site_id,
    plan_id=plan.plan_id,
    template_id=image.template_id,
    os_distro=image.os_distro,
    os_type=image.os_type,
    cpu=plan.cpu,
    ram_mb=plan.ram_mb,
    disk_gb=plan.disk_gb,
    ssh_key_ids=ssh_key_ids,
    tags=["example"],
    request_options={"additional_body_parameters": {"billing_catalog": billing_catalog}},
)
vm_id = accepted.vm_id
print(f"Creating {name} ({vm_id})")
wait_for(accepted.operation_id)

vm = client.cloud_vms.get_cloud_vm(vm_id=vm_id, workspace_id=WORKSPACE_ID)
print(f"{vm.name} is {vm.status}; public IP {vm.public_ip}, private IP {vm.private_ip}")

# 3. Power actions.
print("Stopping")
wait_for(client.cloud_vms.stop_cloud_vm(vm_id=vm_id, workspace_id=WORKSPACE_ID, idempotency_key=str(uuid.uuid4())).operation_id)
print("Starting")
wait_for(client.cloud_vms.start_cloud_vm(vm_id=vm_id, workspace_id=WORKSPACE_ID, idempotency_key=str(uuid.uuid4())).operation_id)

# 4. Delete the VM and release its automatic public IP ("reserve" keeps it as a Reserved IP).
if os.getenv("KEEP") == "1":
    print(f"Keeping {vm_id}")
else:
    print("Deleting")
    deleted = client.cloud_vms.delete_cloud_vm(
        vm_id=vm_id,
        workspace_id=WORKSPACE_ID,
        idempotency_key=f"delete-{vm_id}",
        request_options={"additional_body_parameters": {"public_ip_action": "release"}},
    )
    wait_for(deleted.operation_id)
