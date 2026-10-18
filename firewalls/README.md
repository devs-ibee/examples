# Firewalls

Create a firewall group with rules that allow HTTP and HTTPS from anywhere, attach it to a VM, then detach and delete it. Add the rules before you attach the group, so the VM never runs with a partial rule set.

```bash
export IBEE_VM_ID=...

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

To allow SSH from your network only, add a rule for port 22 with `remote_targets=["198.51.100.7/32"]`.

Token scopes: `firewall.read`, `firewall.write`.
