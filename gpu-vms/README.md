# GPU VMs

Create a GPU VM, wait for it, read it, then delete it. GPU VMs work like [Cloud VMs](../cloud-vms/) with GPU plans and images.

```bash
export IBEE_SITE_ID=...
export IBEE_GPU_PLAN_ID=...       # ibee compute plans --vm-type gpu
export IBEE_GPU_TEMPLATE_ID=...   # ibee compute images --vm-type gpu

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

GPU plans are available only to workspaces with GPU access. Once the VM runs, `ssh` to its public IP and run `nvidia-smi`.

Token scopes: `vm.read`, `vm.write`. This creates a billable GPU VM.
