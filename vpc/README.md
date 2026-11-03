# VPC

Create a private network with one subnet, attach a VM to it, then detach the VM and delete the subnet and the VPC.

```bash
export IBEE_SITE_ID=...   # a networking site: ibee vpcs sites
export IBEE_VM_ID=...     # a VM at that site

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

- `connectivity` on attach is `private` (the default), `nat` or `public_ip`.
- For managed outbound NAT, create the VPC with `connectivity_type="nat_gateway"` (`--connectivity-type nat_gateway`); NAT gateways and port forwarding have their own calls (`ibee vpcs nat`, `ibee vpcs forwarding`).

Token scopes: `network.read`, `network.write`.
