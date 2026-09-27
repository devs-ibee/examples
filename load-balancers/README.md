# Load Balancers

Spread traffic across VMs with a layer 7 HTTP load balancer that routes `/api` to a separate port, and a layer 4 TCP load balancer.

## What it does

1. Creates an L7 HTTP load balancer across the backend IPs on port 80, with requests under `/api` sent to port 8080 and round-robin balancing.
2. Creates an L4 TCP load balancer across the same backends on port 5432.
3. Waits until both are `active` and prints their endpoints.
4. Deletes both. Set `KEEP=1` to keep them.

## Requirements

- An API token with `load-balancer.read` and `load-balancer.write`.
- `IBEE_BACKEND_IPS`: comma-separated IP addresses of the backend VMs, reachable from the load balancer.
- Load balancers are billed while they exist.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_BACKEND_IPS="203.0.113.10,203.0.113.11"

python3 main.py
bash cli.sh
```

## Options

| Setting | Values |
|---|---|
| L7 `protocol` | `http`, `https` |
| L4 `protocol` | `tcp`, `tls_passthrough` |
| Backend `type` | `ip`, `hostname`, `service` |
| Backend `weight` | 1 to 1000 (default 100) |
| `routing.algorithm` | `round_robin`, `least_request`, `random`, `consistent_hash` |
| `tls.mode` | `terminate` (L7 HTTPS) or `passthrough` (L4) |
| Rule matching | `path_prefix`, `headers`, and `priority` on L7 rules |
