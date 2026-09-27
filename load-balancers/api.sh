#!/usr/bin/env bash
# Load Balancers with plain HTTP calls: an L7 HTTP balancer with path routing and an L4 TCP balancer.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BACKEND_IPS (comma-separated),
#              optional IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
set -euo pipefail

if [[ "${IBEE_ENV:-}" == "dev" ]]; then API="https://api.ibee.co.in/v1"; else API="https://api.ibee.ai/v1"; fi
API="${IBEE_API_URL:-$API}"

# api METHOD PATH [JSON_BODY] [EXTRA_HEADER]
# Sends the token as a bearer token and the workspace as the workspace_id query parameter.
api() {
  local method="$1" path="$2" body="${3:-}" header="${4:-}" sep="?"
  [[ "$path" == *\?* ]] && sep="&"
  curl -sS --fail-with-body -X "$method" \
    -H "Authorization: Bearer $IBEE_TOKEN" \
    -H "Content-Type: application/json" \
    ${header:+-H "$header"} \
    ${body:+--data "$body"} \
    "$API$path${sep}workspace_id=$IBEE_WORKSPACE_ID"
}

backends() {  # backends PORT -> JSON array of IP backends
  jq -cn --arg ips "$IBEE_BACKEND_IPS" --argjson port "$1" '$ips | split(",") | map({type: "ip", target: ., port: $port})'
}

# Wait until a load balancer is active and print its endpoint.
wait_active() {
  local lb_id="$1" status
  for _ in $(seq 1 90); do
    status=$(api GET "/networking/load-balancers/$lb_id/status")
    case "$(jq -r .status <<<"$status")" in
      active) echo "$lb_id is active at $(jq -r .endpoint_url <<<"$status")"; return 0 ;;
      failed) echo "$lb_id failed: $(jq -r '.error_message // ""' <<<"$status")" >&2; return 1 ;;
    esac
    sleep 10
  done
  return 1
}

WEB_ID=$(api POST /networking/load-balancers/l7 "$(jq -n --argjson web "$(backends 80)" --argjson api "$(backends 8080)" '{
  name: "example-web", protocol: "http", backends: $web,
  routing: {algorithm: "round_robin"},
  rules: [{priority: 10, path_prefix: "/api", backends: $api}]
}')" | jq -r .lb_id)

TCP_ID=$(api POST /networking/load-balancers/l4 "$(jq -n --argjson b "$(backends 5432)" \
  '{name: "example-postgres", protocol: "tcp", backends: $b}')" | jq -r .lb_id)

wait_active "$WEB_ID"
wait_active "$TCP_ID"

if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/networking/load-balancers/$WEB_ID" >/dev/null
  api DELETE "/networking/load-balancers/$TCP_ID" >/dev/null
  echo "Deleted both load balancers"
fi
