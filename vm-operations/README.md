# VM operations

Day-2 work on an existing Cloud VM: read its metrics and recent events, then move it to another plan (stop, resize, start).

```bash
export IBEE_VM_ID=...         # a Cloud VM, for example from cloud-vms with the delete step removed
export IBEE_NEW_PLAN_ID=...   # the plan to move to, from getting-started

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

The API checks every resize and refuses what it cannot do, such as shrinking the root disk. To see its answer without changing anything, call `precheck_cloud_vm_resize` (`ibee vms resize-precheck`) first.

Token scopes: `vm.read`, `vm.write`.
