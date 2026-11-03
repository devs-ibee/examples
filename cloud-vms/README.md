# Cloud VMs

Create a Cloud VM, wait for it, read it, then delete it and release its public IP.

```bash
export IBEE_SITE_ID=... IBEE_PLAN_ID=... IBEE_TEMPLATE_ID=...   # from getting-started

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- The SDKs and the CLI send only what you pass, so the example copies `cpu`, `ram_mb` and `disk_gb` from the plan and `os_type` and `os_distro` from the image.
- `billing_catalog` is the plan's `billing_catalog` with one of its `billing_options` merged in: `HOURLY`, or `MONTHLY` for a one-month commitment. The CLI builds it for you with `--billing-interval HOURLY`.
- Create, delete and power actions return an operation; poll `get_compute_operation` (`ibee ops get OPERATION_ID`) until it is `succeeded`.
- To log in, add `ssh_keys=["ssh-ed25519 ..."]` (`--ssh-keys`), or `ssh_key_ids=[...]` (`--ssh-key-ids`) with an SSH key from the portal.
- Deleting a VM with an automatic public IP needs `public_ip_action`: `"release"` gives the address up, `"reserve"` keeps it as a Reserved IP (`--public-ip-action`).

Token scopes: `vm.read`, `vm.write`. This creates a billable VM for a few minutes.
