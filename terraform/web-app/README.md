# Web app behind a load balancer

Two Cloud VMs running your web server, a firewall that allows HTTP and HTTPS from anywhere and SSH only from your network, and an L7 load balancer in front of them.

## Inputs

| Variable | Description |
|---|---|
| `site_id` | Compute site for the VMs (required) |
| `vm_count` | Number of web VMs (default 2) |
| `plan_id` | VM plan; defaults to the cheapest priced plan at the site |
| `ssh_key_ids` | SSH keys to install on the VMs |
| `admin_cidr` | Network allowed to use SSH, for example `198.51.100.7/32` |

## Run it

```bash
terraform apply -var site_id=<site-id> -var 'ssh_key_ids=["<ssh-key-id>"]' -var admin_cidr=198.51.100.7/32
```

The VMs start from a plain Ubuntu image. Install your web server once they are running, for example:

```bash
for ip in $(terraform output -json vm_public_ips | jq -r '.[]'); do
  ssh ubuntu@"$ip" 'sudo apt-get update && sudo apt-get install -y nginx'
done
curl "$(terraform output -raw load_balancer_url)"
```
