# Snapshots and backups

Take a snapshot of a Cloud VM's root disk, list its snapshots and backup runs, then delete the snapshot.

```bash
export IBEE_VM_ID=...

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- A snapshot is billed for its storage, so the request carries a snapshot storage plan's `billing_catalog`, unchanged. The example takes the first selectable plan from `list_snapshot_storage_plans` (`ibee compute snapshot-storage-plans`). A backup policy takes a backup storage plan the same way: `list_backup_storage_plans` and `enable_cloud_vm_backups` (`ibee compute backup-storage-plans`, then `ibee vms backup-policy enable VM_ID --billing-catalog @plan.json`).
- Use `mode="all_attached"` to include the VM's data volumes.
- Restore with `restore_cloud_vm_snapshot` or `restore_cloud_vm_backup` (`ibee vms snapshots restore SNAPSHOT_SET_ID --vm-id VM_ID`, `ibee vms backups restore VM_ID --recovery-point-id RECOVERY_POINT_ID`).

Token scopes: `vm.read`, `vm.write`. Snapshots are billed for the storage they use.
