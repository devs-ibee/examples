#!/usr/bin/env bash
# Firewalls with plain HTTP calls: a web-server firewall group attached to a VM.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ADMIN_CIDR,
#              IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
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

GROUP_ID=$(api POST /networking/firewall-groups '{"name": "web", "description": "HTTP, HTTPS, and admin SSH"}' |
  jq -r .firewall_group_id)

rule() {  # rule PORT CIDR DESCRIPTION
  jq -n --argjson port "$1" --arg cidr "$2" --arg description "$3" '{
    description: $description, direction: "ingress", protocol: "tcp",
    port_start: $port, port_end: $port, remote_targets: [$cidr], action: "allow"
  }'
}
api POST "/networking/firewall-groups/$GROUP_ID/rules" "$(rule 80 0.0.0.0/0 "Allow TCP 80")" >/dev/null
api POST "/networking/firewall-groups/$GROUP_ID/rules" "$(rule 443 0.0.0.0/0 "Allow TCP 443")" >/dev/null
if [[ -n "${IBEE_ADMIN_CIDR:-}" ]]; then
  api POST "/networking/firewall-groups/$GROUP_ID/rules" "$(rule 22 "$IBEE_ADMIN_CIDR" "Admin SSH")" >/dev/null
fi
api GET "/networking/firewall-groups/$GROUP_ID" |
  jq -r '.rules[] | "  \(.direction) \(.protocol) \(.port_start)-\(.port_end) from \(.remote_targets | join(",")): \(.action)"'

# Attach after the rules exist.
api POST "/networking/firewall-groups/$GROUP_ID/attachments" "$(jq -n --arg vm "$IBEE_VM_ID" '{vm_id: $vm}')" >/dev/null
api GET "/networking/firewall-groups/$GROUP_ID/attachments" | jq .

if [[ "${KEEP:-}" != "1" ]]; then
  api DELETE "/networking/firewall-groups/$GROUP_ID/attachments/$IBEE_VM_ID" >/dev/null
  api DELETE "/networking/firewall-groups/$GROUP_ID" >/dev/null
  echo "Deleted firewall group $GROUP_ID"
fi
