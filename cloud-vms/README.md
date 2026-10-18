# Cloud VMs

Create a Cloud VM, wait for it, read it, then delete it and release its public IP.

```bash
export IBEE_SITE_ID=... IBEE_PLAN_ID=... IBEE_TEMPLATE_ID=...   # from getting-started

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- Create, delete and power actions return an operation; poll `get_compute_operation` (or pass `--wait` to the CLI) until it is `succeeded`.
- `billing_term` is the plan's billing option to buy (`HOURLY`, `MONTHLY`, ...).
- To log in, add `ssh_key_ids=[...]` (`--ssh-key-id`) with an SSH key from the portal.
- `public_ip_action="reserve"` keeps the address as a Reserved IP instead of releasing it.

Token scopes: `vm.read`, `vm.write`. This creates a billable VM for a few minutes.
