#!/usr/bin/env bash
# The same calls with curl: a bearer token and a workspace_id query parameter.
set -euo pipefail

API="${IBEE_API_URL:-https://api.ibee.ai/v1}"   # https://api.ibee.co.in/v1 for development
auth=(-H "Authorization: Bearer $IBEE_TOKEN")
ws="workspace_id=$IBEE_WORKSPACE_ID"

curl -sS --fail-with-body "${auth[@]}" "$API/compute/sites?$ws" | jq '.sites[] | {site_id, name}'
curl -sS --fail-with-body "${auth[@]}" "$API/compute/plans?vm_type=cloud&$ws" | jq '.plans[] | {plan_id, name, cpu, ram_mb, site_id}'
curl -sS --fail-with-body "${auth[@]}" "$API/compute/images?vm_type=cloud&$ws" | jq '.images[] | {template_id, name}'
