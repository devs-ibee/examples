# Snapshots and backups

Take a snapshot of a Cloud VM's root disk, list its snapshots and backup runs, then delete the snapshot.

```bash
export IBEE_VM_ID=...
export IBEE_SNAPSHOT_SKU_ID=... IBEE_SNAPSHOT_SKU_CODE=...

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- The API needs the snapshot storage SKU as `billing_catalog` (`sku_id` and `sku_code`). Use `GET /compute/snapshot-storage-plans` to discover it. Backup policies use the backup storage SKU from `GET /compute/backup-storage-plans`; manual backup runs can inherit the enabled policy catalog.
- Use `mode="all_attached"` to include the VM's data volumes.
- Restore with `restore_cloud_vm_snapshot` or `restore_cloud_vm_backup` (`ibee vms snapshots restore`, `ibee vms backups restore`).

Token scopes: `vm.read`, `vm.write`. Snapshots are billed for the storage they use.

With the contract 0.9 clients, start a manual backup using `create_cloud_vm_backup_run(vm_id)`
(Python), `cloudVms.createCloudVmBackupRun({vm_id})` (TypeScript), or
`ibee vms backups create VM_ID`. Backups must be enabled first; a queued or
running backup returns 409. Cancel a queued restore with
`cancel_cloud_vm_backup_restore(restore_id)` or
`ibee vms backups restore-cancel RESTORE_ID --yes`. GPU equivalents use `gpu_vms`/`gpuVms`/`gpus`.
