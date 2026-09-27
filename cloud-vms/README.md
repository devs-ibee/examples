# Cloud VMs

Create a Cloud VM the same way the portal does, wait for it to run, stop and start it, then delete it and release its public IP.

## What it does

1. Picks a site (`IBEE_SITE_ID`, or the first compute site).
2. Picks the cheapest priced plan and an Ubuntu image available at that site.
3. Creates the VM and waits for the create operation to succeed.
4. Prints the VM's status and public IP.
5. Stops the VM, then starts it again.
6. Deletes the VM and releases its automatically assigned public IP. Set `KEEP=1` to keep the VM.

VM actions are asynchronous. Each call returns an `operation_id`; poll the operation until its status is `succeeded`, `failed`, `cancelled`, or `timed_out`.

## Requirements

- An API token with `vm.read` and `vm.write`.
- Billing set up for the organization. This example creates a billable VM and runs it for a few minutes.
- Optional: `IBEE_SSH_KEY_ID`, the ID of an SSH key added under **Tools → SSH Keys**, to log in to the VM.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"

python3 main.py            # full lifecycle with the Python SDK
npx tsx index.ts           # full lifecycle with the TypeScript SDK
bash api.sh                # full lifecycle with curl and jq
IBEE_VM_ID=<vm-id> bash cli.sh   # day-2 operations on an existing VM with the ibee CLI
```

## Things to know

- **Send the plan's `billing_catalog`.** The create request must include the `billing_catalog` object returned with the chosen plan by `GET /compute/plans`, passed through unchanged. The 0.3.0 SDKs do not have a named argument for it yet, so the examples pass it as an extra body field.
- **Choose what happens to the public IP on delete.** A VM with an automatically assigned public IP must be deleted with the body `{"public_ip_action": "release"}` or `{"public_ip_action": "reserve"}`. `reserve` keeps the address as a Reserved IP, which continues to bill.
- **Use idempotency keys.** Create, delete, and power actions require an `X-Idempotency-Key` header. Reuse the same key when you retry the same request, so a retry never creates a second VM.
- **CLI 0.3.0 cannot create or delete VMs** against the current API, because it cannot send `billing_catalog` or `public_ip_action`. Use the SDK or HTTP examples for those steps; the CLI handles everything else.
