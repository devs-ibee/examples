# Load Balancers

Create a regional HTTP load balancer that sends port 80 to two VMs, read its address, change its health check, then delete it.

```bash
export IBEE_BACKEND_VM_IDS=VM_ID_1,VM_ID_2      # VMs with their own public IP, serving port 80

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- A load balancer is one specification. `listeners` are the ports it answers on (`HTTP`, `HTTPS`, `TCP` or `UDP`), and each sends traffic to one of the `target_groups`, which carry the targets and their health check. `traffic_type` is `http` (layer 7) or `network` (layer 4).
- Targets are VMs (`kind: "vm"` with `resource_id`) that have their own public IP. Private addresses (`kind: "ip"`, in 10/8, 172.16/12 or 192.168/16, with the load balancer's `vpc_id`) only work in a region whose `capabilities.private_targets` is `true`. A target the region can't reach is refused with `422 target_not_usable` before anything is reserved.
- Leave `unhealthy_threshold` out of the health check: the service uses `1` for an `HTTP` check and `3` for `TCP`.
- The public address is in `conditions.addresses` once `conditions.frontend_ready` is true. To use your own domain, point an A record at it.
- A new VM reports `running` about 20 seconds before its web server answers. Wait for it before testing traffic through the load balancer.
- `GET /networking/load-balancers` hides deleted load balancers; add `include_deleted=true` to see them.
- Pick a region from `list_load_balancer_regions` (`ibee load-balancers regions`); the examples take the first.
- Create, update and delete return an operation. Poll `get_load_balancer_operation` (`ibee load-balancers operation OPERATION_ID`) until `completed_at` is set; `status` and `reason` say how it ended.
- An update replaces the whole specification and sends the `version` read with `get_load_balancer`; a stale version answers 409.
- `rules` on an HTTP listener send paths such as `/api` to another target group.
- A load balancer whose `managed_by` is `ccm` belongs to a Kubernetes cluster and can't be changed here.

Token scopes: `load-balancer.read`, `load-balancer.write`. Billed per node per hour (`node_count`, default 1) while it exists.
