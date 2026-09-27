# Private network with NAT

A VPC whose VMs reach the internet through a managed NAT gateway, with SSH published on the NAT gateway's public IP.

## Inputs

| Variable | Description |
|---|---|
| `vm_id` | Existing VM to attach, at the VPC's site (required) |
| `site_id` | Networking site; defaults to the first available one |
| `cidr` | VPC range (default `10.44.0.0/22`) |

## Run it

```bash
terraform apply -var vm_id=<vm-id>
ssh -p 2222 ubuntu@"$(terraform output -raw nat_public_ip)"
```

The VPC owns its NAT gateway: destroying the VPC removes it. Terraform removes the forwarding rule, attachment, and subnet first.
