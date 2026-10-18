#!/usr/bin/env bash
# Create an HTTP load balancer in front of two backends, read its status, and delete it, with the ibee CLI.
set -euo pipefail

BACKENDS=$(jq -nc --arg ips "$IBEE_BACKEND_IPS" '$ips | split(",") | map({type: "ip", target: ., port: 80})')
LB_ID=$(ibee --json load-balancers create-l7 example-web --protocol http --backends "$BACKENDS" | jq -r .lb_id)

ibee load-balancers status "$LB_ID"
ibee load-balancers delete "$LB_ID" --yes
