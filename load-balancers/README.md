# Load Balancers

Create an L7 HTTP load balancer in front of two backend VMs, read its status and endpoint, then delete it.

```bash
export IBEE_BACKEND_IPS=203.0.113.10,203.0.113.11   # your backend VM addresses

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

A new load balancer takes a few minutes to become `active`. Use `create_l4load_balancer` (`ibee load-balancers create-l4`) for raw TCP, and `rules` on an L7 balancer to route paths such as `/api` to other backends.

Token scopes: `load-balancer.read`, `load-balancer.write`.
