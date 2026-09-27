# VPC and NAT gateway

Put a VM on a private network with outbound internet through a managed NAT gateway, and publish one port (SSH) through NAT port forwarding.

## What it does

1. Creates a VPC with `nat_gateway` connectivity and the CIDR `10.44.0.0/22`. The NAT gateway is created with the VPC.
2. Creates the subnet `10.44.0.0/24`.
3. Attaches the VM (`IBEE_VM_ID`) to the subnet with NAT connectivity. The platform assigns the next free private address.
4. Forwards port 2222 on the NAT gateway's public IP to port 22 on the VM.
5. Removes everything in reverse order. Set `KEEP=1` to keep the network.

## Requirements

- An API token with `network.read` and `network.write`.
- A Cloud VM (`IBEE_VM_ID`) at the same site as the VPC (`IBEE_SITE_ID`, or the first available networking site).
- The NAT gateway is billed while it exists.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VM_ID="<vm-id>"

python3 main.py
npx tsx index.ts
bash cli.sh
```

## Connectivity options

| `connectivity` when attaching a VM | Result |
|---|---|
| `private` | Private address only; no internet access |
| `nat` | Private address with outbound internet through the VPC's NAT gateway (requires a `nat_gateway` VPC) |
| `public_ip` | Private address plus a dedicated public IP; pass `reserved_public_ip_id` to use a [Reserved IP](../reserved-ips/) |

To pick a specific private address for a Kubernetes load balancer, see [Virtual IPs](../virtual-ips/).
