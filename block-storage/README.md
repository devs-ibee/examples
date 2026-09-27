# Block Storage

Create a persistent volume, attach it to a Cloud VM, grow it, then detach and delete it.

## What it does

1. Creates a 20 GB `balanced` volume at the VM's site and waits until it is `ready`.
2. Attaches it to the VM (`IBEE_VM_ID`) and records that you reviewed the mount instructions.
3. Grows the volume to 30 GB.
4. Detaches and deletes it. Set `KEEP=1` to keep the volume attached.

## Requirements

- An API token with `block-storage.read`, `block-storage.write`, `vm.read`, and `vm.write`.
- A Cloud VM (`IBEE_VM_ID`) and its site (`IBEE_SITE_ID`). A volume can only attach to a VM at the same site.
- Optional: `IBEE_BLOCK_SKU`, a Block Storage SKU from the portal, when your site offers more than one.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VM_ID="<vm-id>"
export IBEE_SITE_ID="<site-id>"

python3 main.py
bash cli.sh
```

## Use the volume inside the VM

After the attach succeeds, format and mount the new disk from inside the VM. Check the device name with `lsblk` first; it is usually the last disk listed.

```bash
lsblk
sudo mkfs.ext4 /dev/vdb            # only for a new, empty volume
sudo mkdir -p /mnt/data
sudo mount /dev/vdb /mnt/data
echo "UUID=$(sudo blkid -s UUID -o value /dev/vdb) /mnt/data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
```

After growing a mounted ext4 volume, run `sudo resize2fs /dev/vdb` inside the VM to use the new space.

**Unmount before you detach.** Run `sudo umount /mnt/data` and remove the `/etc/fstab` line first. The detach call requires `confirm_unmounted` to make that step explicit; detaching a mounted volume can corrupt data.
