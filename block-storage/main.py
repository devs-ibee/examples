"""Block Storage: create a volume, attach it to a VM, grow it, detach, and delete.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (block-storage.read/write, vm.read/write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_VM_ID         Cloud VM to attach the volume to
  IBEE_SITE_ID       the VM's site; volumes attach only within one site
  IBEE_BLOCK_SKU     Block Storage SKU (optional)
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to leave the volume attached
"""

import os
import time
import uuid

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
VM_ID = os.environ["IBEE_VM_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)


def wait_for_volume(volume_id, states=("ready", "in-use"), timeout_seconds=900):
    deadline = time.monotonic() + timeout_seconds
    while True:
        volume = client.block_storage.get_block_volume(volume_id=volume_id, workspace_id=WORKSPACE_ID)
        if volume["state"] in states:
            return volume
        if volume["state"] == "error" or time.monotonic() > deadline:
            raise RuntimeError(f"volume {volume_id} is {volume['state']}")
        time.sleep(5)


def wait_for_operation(operation_id):
    while True:
        op = client.cloud_vms.get_compute_operation(operation_id=operation_id, workspace_id=WORKSPACE_ID)
        if op.status in {"succeeded", "failed", "cancelled", "timed_out"}:
            break
        time.sleep(5)
    if op.status != "succeeded":
        raise RuntimeError(f"{op.action} {op.status}: {op.error_message}")


# 1. Create a volume at the VM's site.
created = client.block_storage.create_block_volume(
    workspace_id=WORKSPACE_ID,
    name=f"example-data-{uuid.uuid4().hex[:6]}",
    size_gb=20,
    site_id=os.environ["IBEE_SITE_ID"],
    sku_code=os.getenv("IBEE_BLOCK_SKU") or None,
    volume_class="balanced",
)
volume_id = created["volume"]["id"]
volume = wait_for_volume(volume_id)
print(f"Volume {volume['name']} ({volume_id}) is {volume['state']}, {volume['size_gb']} GB")

# 2. Attach it to the VM. The VM operation completes once the disk is visible to the guest.
attach = client.cloud_vms.attach_cloud_vm_volume(
    vm_id=VM_ID, workspace_id=WORKSPACE_ID, idempotency_key=f"attach-{volume_id}", volume_id=volume_id
)
wait_for_operation(attach.operation_id)
client.cloud_vms.acknowledge_cloud_vm_mount_guidance(vm_id=VM_ID, workspace_id=WORKSPACE_ID, volume_id=volume_id)
print("Attached. Format and mount it inside the VM (see README.md).")

# 3. Grow the volume. Shrinking is not supported.
client.block_storage.resize_block_volume(
    volume_id=volume_id, workspace_id=WORKSPACE_ID, new_size_gb=30, vm_state="running", allow_online=True
)
volume = wait_for_volume(volume_id)
print(f"Resized to {volume['size_gb']} GB. Run resize2fs inside the VM to use the space.")

# 4. Detach and delete. Unmount the filesystem inside the VM before detaching.
if os.getenv("KEEP") != "1":
    detach = client.cloud_vms.detach_cloud_vm_volume(
        vm_id=VM_ID,
        workspace_id=WORKSPACE_ID,
        idempotency_key=f"detach-{volume_id}",
        volume_id=volume_id,
        confirm_unmounted=True,  # you ran `sudo umount` inside the VM first
    )
    wait_for_operation(detach.operation_id)
    wait_for_volume(volume_id, states=("ready",))
    client.block_storage.delete_block_volume(volume_id=volume_id, workspace_id=WORKSPACE_ID)
    print(f"Deleted {volume_id}")
