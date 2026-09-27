# Firewalls

Create a firewall group for a web server, allow HTTP and HTTPS from anywhere and SSH only from your network, and attach it to a VM.

## What it does

1. Creates the firewall group `web`.
2. Adds ingress rules for TCP 80 and 443 from `0.0.0.0/0`.
3. With `IBEE_ADMIN_CIDR` set, adds an ingress rule for TCP 22 from that range only.
4. Attaches the group to the VM (`IBEE_VM_ID`) and lists its attachments.
5. Detaches and deletes the group. Set `KEEP=1` to keep it.

## Requirements

- An API token with `firewall.read` and `firewall.write`.
- A Cloud VM (`IBEE_VM_ID`).
- Optional: `IBEE_ADMIN_CIDR`, for example your office's public IP as `198.51.100.7/32`.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VM_ID="<vm-id>"
export IBEE_ADMIN_CIDR="198.51.100.7/32"

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
bash api.sh          # curl and jq
```

Create all rules before attaching a group, so the VM never runs with a partial rule set. Each rule has a `direction` (`ingress` or `egress`), a `protocol` (`tcp`, `udp`, `icmp`, or `any`), a port range, a list of `remote_targets` in CIDR form, an `action` (`allow` or `drop`), and an optional `priority`.
