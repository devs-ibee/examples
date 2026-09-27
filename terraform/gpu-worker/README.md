# GPU worker

A GPU VM for training or inference, a block volume for datasets and checkpoints, and weekly backups of the VM.

## Inputs

| Variable | Description |
|---|---|
| `site_id` | Site with GPU plans (required) |
| `plan_id` | GPU plan; defaults to the cheapest priced GPU plan at the site |
| `block_sku_code` | Active Block Storage SKU from the portal (required) |
| `data_volume_gb` | Size of the dataset volume (default 200) |
| `ssh_key_ids` | SSH keys to install |
| `confirm_volume_unmounted` | Set to `true` only after unmounting the volume inside the VM, before destroy |

## Run it

```bash
terraform apply -var site_id=<site-id> -var block_sku_code=<sku> -var 'ssh_key_ids=["<ssh-key-id>"]'
terraform output mount_instructions
```

GPU plans are offered at a subset of sites and may need GPU access enabled for your organization. Before `terraform destroy`, unmount the volume inside the VM and apply once with `-var confirm_volume_unmounted=true`.
