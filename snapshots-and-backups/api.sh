#!/usr/bin/env bash
# Scheduled backups, an on-demand backup, a snapshot, and recovery points with plain HTTP calls.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev.
# IBEE_API_URL overrides the API base URL.
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

VM="/compute/cloud-vms/$IBEE_VM_ID"

# 1. Daily backups at 20:00 UTC, keeping seven days of recovery points.
api POST "$VM/backups/enable" '{
  "schedule": {"frequency": "daily", "timezone": "UTC", "hour": 20, "minute": 0},
  "retention_days": 7,
  "incremental_enabled": true
}' | jq '{policy_id, enabled, next_run_at}'

# 2. An on-demand backup.
api POST "$VM/backups/runs" '{"reason": "before upgrade"}' | jq '{run_id, status}'

# 3. A snapshot of the root disk ("all_attached" also captures data volumes).
api POST "$VM/snapshots" "$(jq -n --arg name "before-upgrade-$(date +%Y%m%d)" '{name: $name, mode: "root_only"}')" |
  jq '{snapshot_set_id, status}'

# 4. Recovery points you can restore from.
api GET "$VM/backups/runs?limit=10" | jq -r '.runs[] | "backup   \(.run_id)  \(.status)  recovery point \(.recovery_point_id)"'
api GET "$VM/snapshots?limit=10" | jq -r '.snapshots[] | "snapshot \(.snapshot_set_id)  \(.name)  \(.status)"'
