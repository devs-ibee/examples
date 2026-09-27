#!/usr/bin/env bash
# Load Balancers with the ibee CLI: an L7 HTTP balancer with path routing and an L4 TCP balancer.
#
# Requires: pip install ibee-cli, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BACKEND_IPS (comma-separated),
#              optional IBEE_ENV=dev, KEEP=1
set -euo pipefail

backends() {  # backends PORT -> JSON array of IP backends
  jq -cn --arg ips "$IBEE_BACKEND_IPS" --argjson port "$1" \
    '$ips | split(",") | map({type: "ip", target: ., port: $port})'
}

WEB_ID=$(ibee --json load-balancers create-l7 example-web --protocol http \
  --backends "$(backends 80)" \
  --routing '{"algorithm": "round_robin"}' \
  --rules "$(jq -cn --argjson b "$(backends 8080)" '[{priority: 10, path_prefix: "/api", backends: $b}]')" |
  jq -r .lb_id)

TCP_ID=$(ibee --json load-balancers create-l4 example-postgres --protocol tcp \
  --backends "$(backends 5432)" | jq -r .lb_id)

ibee load-balancers status "$WEB_ID"
ibee load-balancers status "$TCP_ID"
ibee load-balancers list

if [[ "${KEEP:-}" != "1" ]]; then
  ibee load-balancers delete "$WEB_ID" --yes
  ibee load-balancers delete "$TCP_ID" --yes
fi
