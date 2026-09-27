# Snapshots and backups

Protect a Cloud VM with scheduled backups, take an on-demand backup, capture a snapshot, and list the recovery points you can restore from.

## What it does

1. Enables daily backups at 20:00 UTC, keeping 7 days of recovery points.
2. Queues an on-demand backup run.
3. Takes a snapshot of the root disk.
4. Lists backup runs and snapshots for the VM.

## Requirements

- An API token with `vm.read` and `vm.write`.
- An existing Cloud VM (`IBEE_VM_ID`).
- Backups and snapshots are billed for the storage they use, and recovery points are kept until they expire or you delete them.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VM_ID="<vm-id>"

python3 main.py
bash cli.sh
```

## Restoring

A restore can replace the VM, create a new VM, or restore a single volume (`target_mode` of `replace`, `new_vm`, or `volume_only`). Restoring with `replace` overwrites the VM's disks. Follow [Restore from backup](https://ibee.ai/docs/tools/backups/restore-from-backup) and [Restore a snapshot](https://ibee.ai/docs/tools/snapshots/restore-a-snapshot) to choose the right mode, then poll the returned restore ID until it completes.

GPU VMs have the same operations through the `gpu_vms` client and `ibee gpus` commands.
