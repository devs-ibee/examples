"""Create a Block Storage volume, attach it to a Cloud VM, detach it, and delete it."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
VM_ID = os.environ["IBEE_VM_ID"]


def wait(accepted):
    """Poll a VM operation until it finishes."""
    while True:
        op = client.cloud_vms.get_compute_operation(accepted.operation_id)
        if op.status in ("succeeded", "failed", "cancelled", "timed_out"):
            print(f"{op.action}: {op.status} {op.error_message or ''}")
            return op
        time.sleep(5)


created = client.block_storage.create_block_volume(
    name="example-data",
    size_gb=20,
    site_id=os.environ["IBEE_SITE_ID"],  # the VM's site
    sku_code=os.environ["IBEE_BLOCK_SKU"],
)
volume_id = created.volume.id
while (volume := client.block_storage.get_block_volume(volume_id)).state != "ready":
    time.sleep(5)
print(f"Volume {volume.name} is {volume.state}, {volume.size_gb} GB")

# The attachment is billed under the volume's Block Storage SKU, from the volume's metadata.
catalog = volume.metadata.billing_catalog
wait(client.cloud_vms.attach_cloud_vm_volume(VM_ID, volume_id=volume_id, billing_catalog=catalog))
# Format and mount it inside the VM now (see README.md). Unmount before detaching.
wait(client.cloud_vms.detach_cloud_vm_volume(VM_ID, volume_id=volume_id, confirm_unmounted=True))

client.block_storage.delete_block_volume(volume_id)
