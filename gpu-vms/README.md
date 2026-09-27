# GPU VMs

Create a GPU VM from a priced GPU plan and a GPU-compatible image, wait for it to run, then delete it.

## What it does

1. Picks a site with GPU plans (`IBEE_SITE_ID`, or the first site that has one).
2. Picks the cheapest priced GPU plan and a GPU-compatible Ubuntu image.
3. Creates the GPU VM, waits for it to run, and prints its IP addresses.
4. Deletes the VM and releases its public IP. Set `KEEP=1` to keep it.

## Requirements

- An API token with `vm.read` and `vm.write`.
- GPU access for your organization. GPU plans are offered at a subset of sites, and some organizations need GPU access enabled first. If creation is refused with `403`, contact support.
- Optional: `IBEE_GPU_MODEL` when the chosen plan does not report its GPU model, and `IBEE_SSH_KEY_ID` to log in.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
python3 main.py
```

GPU VMs support the same power, resize, volume, snapshot, and backup operations as Cloud VMs through the `gpu_vms` client (`ibee gpus ...` in the CLI). The [Cloud VMs](../cloud-vms/) example explains `billing_catalog`, `public_ip_action`, and idempotency keys, which work the same way here.
