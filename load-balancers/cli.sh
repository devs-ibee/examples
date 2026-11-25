#!/usr/bin/env bash
# Create a regional HTTP load balancer in front of two VMs, change it, and delete it, with the ibee CLI.
set -euo pipefail

# Poll a load balancer operation until it finishes.
wait_op() {
  while true; do
    op=$(ibee --json load-balancers operation "$1")
    if [ "$(jq -r .completed_at <<<"$op")" != null ]; then
      jq -r '"\(.kind): \(.status) \(.reason // "")"' <<<"$op"
      return
    fi
    sleep 10
  done
}

# Targets are VMs with their own public IP, by ID. Private addresses ({"kind": "ip"}) only work in a
# region whose capabilities.private_targets is true, and then also need --vpc-id.
# Leave unhealthy_threshold out: the service uses 1 for HTTP checks and 3 for TCP.
target_groups() {
  jq -nc --arg vms "$IBEE_BACKEND_VM_IDS" --arg path "$1" '[{
    name: "web", protocol: "HTTP",
    targets: ($vms | split(",") | map({kind: "vm", resource_id: ., port: 80})),
    health_check: {protocol: "HTTP", path: $path}
  }]'
}

REGION_ID=$(ibee --json load-balancers regions | jq -r '.[0].id')
# Listeners are the ports it answers on; each sends traffic to a target group.
CREATED=$(ibee --json load-balancers create --name example-web --region-id "$REGION_ID" \
  --traffic-type http --listeners '[{"name": "http", "protocol": "HTTP", "port": 80, "target_group": "web"}]' \
  --target-groups "$(target_groups /)")
wait_op "$(jq -r .id <<<"$CREATED")"
LB_ID=$(jq -r .lb_id <<<"$CREATED")

LB=$(ibee --json load-balancers get "$LB_ID")
# conditions.addresses holds the public address clients connect to.
jq -r '"\(.name) is \(.observed_state) at \(.conditions.addresses[0] // "-"), version \(.version)"' <<<"$LB"

# An update replaces the whole specification and sends the version it was read at.
SPEC=$(jq -c --argjson groups "$(target_groups /healthz)" '.spec | .target_groups = $groups' <<<"$LB")
wait_op "$(ibee --json load-balancers update "$LB_ID" --version "$(jq -r .version <<<"$LB")" --specification "$SPEC" | jq -r .id)"

wait_op "$(ibee --json load-balancers delete "$LB_ID" --yes | jq -r .id)"
