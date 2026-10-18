# Block Storage

Create a 20 GB volume at a VM's site, attach it to the VM, then detach and delete it.

```bash
export IBEE_VM_ID=...      # a Cloud VM
export IBEE_SITE_ID=...    # that VM's site; volumes attach only within a site
export IBEE_BLOCK_SKU=...  # a Block Storage SKU code from the portal

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

Inside the VM, format and mount a new volume (check the device name with `lsblk`):

```bash
sudo mkfs.ext4 /dev/vdb && sudo mkdir -p /mnt/data && sudo mount /dev/vdb /mnt/data
```

Run `sudo umount /mnt/data` before you detach; `confirm_unmounted` records that you did. Grow a volume with `resize_block_volume` (`ibee block-storage resize`).

Token scopes: `block-storage.read`, `block-storage.write`, `vm.read`, `vm.write`.
