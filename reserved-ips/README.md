# Reserved IPs

Reserve a public IP address, attach it to a VM, then detach and release it. A reserved address stays yours until you release it, so you can move it between VMs with `move_reserved_ip` (`ibee reserved-ips move`).

```bash
export IBEE_SITE_ID=...   # the VM's site
export IBEE_VM_ID=...     # add vpc_id/subnet_id (--vpc-id/--subnet-id) for a VM in a VPC

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

Token scopes: `network.read`, `network.write`. A reserved address is billed until it is released.
