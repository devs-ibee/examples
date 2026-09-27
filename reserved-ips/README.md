# Reserved IPs

Reserve a public IPv4 address that stays yours when VMs come and go, attach it to a VM, move it to a replacement VM, and release it.

## What it does

1. Reserves an address at a site and labels it.
2. Attaches it to a VM (`IBEE_VM_ID`) in a VPC subnet.
3. With `IBEE_NEW_VM_ID` set, moves the address to another VM, as you would during a blue-green cut-over.
4. Detaches and releases the address. Set `KEEP=1` to keep it.

## Requirements

- An API token with `network.read` and `network.write`.
- A VM attached to a VPC subnet: `IBEE_VM_ID`, `IBEE_VPC_ID`, and `IBEE_SUBNET_ID`. See the [VPC example](../vpc/).
- The site of that VPC (`IBEE_SITE_ID`).
- A Reserved IP is billed while it is reserved, whether or not it is attached.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_SITE_ID="<site-id>"
export IBEE_VM_ID="<vm-id>"
export IBEE_VPC_ID="<vpc-id>"
export IBEE_SUBNET_ID="<subnet-id>"

python3 main.py
bash cli.sh
```

When you delete a VM that has an automatically assigned public IP, `{"public_ip_action": "reserve"}` converts that address into a Reserved IP instead of releasing it. See the [Cloud VMs example](../cloud-vms/).
