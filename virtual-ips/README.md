# Virtual IPs for MetalLB

Reserve a private address that you choose inside a VPC subnet, authorize the nodes that may announce it, and use it as a stable Kubernetes `LoadBalancer` address with MetalLB.

## What it does

1. Lists the addresses already allocated in the VPC, so you can pick a free one.
2. Reserves the address as a Virtual IP with `purpose: metallb` and your announcer nodes.
3. Lists the VPC's Virtual IPs and reads the new one back.
4. Releases it. Set `KEEP=1` to keep it.

`metallb.yaml` then configures MetalLB to announce that address from the authorized nodes and gives a `LoadBalancer` service that uses it.

## Requirements

- An API token with `network.read` and `network.write`.
- A VPC (`IBEE_VPC_ID`) and subnet (`IBEE_SUBNET_ID`) with Kubernetes nodes attached with NAT connectivity. See the [VPC example](../vpc/).
- `IBEE_VIRTUAL_IP`: an unused host address inside the subnet. The gateway, network, and broadcast addresses are rejected.
- `IBEE_ANNOUNCER_VM_IDS`: comma-separated IDs of the nodes that may announce the address.
- MetalLB 0.14 or later running in the cluster, in layer 2 mode.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VPC_ID="<vpc-id>"
export IBEE_SUBNET_ID="<subnet-id>"
export IBEE_VIRTUAL_IP="10.44.0.50"
export IBEE_ANNOUNCER_VM_IDS="<vm-id-1>,<vm-id-2>"
KEEP=1 bash api.sh

# Label the announcer nodes, then apply the MetalLB configuration.
kubectl label node <node-1> <node-2> ibee.ai/vip-announcer=true
kubectl apply -f metallb.yaml
kubectl get service web
```

Virtual IPs are available through the public API but are not yet part of the SDKs and CLI, so this example uses HTTP calls. To reach the service from the internet, attach a [Reserved IP](https://ibee.ai/docs/network-security/vpc-and-ip-management/reserved-ips) to the Virtual IP from the VPC page in the portal.
