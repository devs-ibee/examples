# Snapshots and backups

Take a snapshot of a Cloud VM's root disk, list its snapshots and backup runs, then delete the snapshot.

```bash
export IBEE_VM_ID=...
export IBEE_SNAPSHOT_SKU_ID=... IBEE_SNAPSHOT_SKU_CODE=...

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- The API needs the snapshot storage SKU as `billing_catalog` (`sku_id` and `sku_code`). No public operation lists it yet; ask IBEE support for it. Backup policies and on-demand backup runs take the backup storage SKU the same way.
- Use `mode="all_attached"` to include the VM's data volumes.
- Restore with `restore_cloud_vm_snapshot` or `restore_cloud_vm_backup` (`ibee vms snapshots restore`, `ibee vms backups restore`).

Token scopes: `vm.read`, `vm.write`. Snapshots are billed for the storage they use.
