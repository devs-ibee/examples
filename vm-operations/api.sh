#!/usr/bin/env bash
# Day-2 Cloud VM operations with plain HTTP calls: metrics, events, resize, SSH access, console.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev,
#              RESIZE=1, IBEE_SSH_PUBLIC_KEY. IBEE_API_URL overrides the API base URL.
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

# Poll an asynchronous VM operation until it finishes.
wait_for() {
  local operation_id="$1" op status
  for _ in $(seq 1 360); do
    op=$(api GET "/compute/operations/$operation_id")
    status=$(jq -r .status <<<"$op")
    case "$status" in
      succeeded) echo "  $(jq -r .action <<<"$op"): succeeded"; return 0 ;;
      failed | cancelled | timed_out) echo "  operation $operation_id $status: $(jq -r '.error_message // ""' <<<"$op")" >&2; return 1 ;;
    esac
    sleep 10
  done
  echo "operation $operation_id did not finish" >&2
  return 1
}

VM="/compute/cloud-vms/$IBEE_VM_ID"
key() { echo "X-Idempotency-Key: $1-$IBEE_VM_ID-$(date +%s)-$RANDOM"; }

# 1. Observability.
CURRENT=$(api GET "$VM")
jq '{name, status, cpu, ram_mb, disk_gb}' <<<"$CURRENT"
api GET "$VM/metrics" | jq .
api GET "$VM/metrics/timeseries?range=1h" | jq '{resolution, series: (.series | keys)}'
api GET "$VM/metrics/bandwidth?month=$(date +%Y-%m)" | jq '{month, rx_bytes, tx_bytes}'
api GET "$VM/events?limit=5" | jq -r '.[] | "\(.created_at)  \(.event_type)  \(.message)"'

# 2. Resize precheck to the next larger priced plan.
TARGET=$(api GET "/compute/plans?vm_type=cloud" | jq -c --argjson vm "$CURRENT" '
  [.plans[] | select(.selectable and .pricing_status == "priced" and ([.cpu, .ram_mb] > [$vm.cpu, $vm.ram_mb]))]
  | sort_by(.cpu, .ram_mb) | .[0] // empty')
if [[ -n "$TARGET" ]]; then
  SHAPE=$(jq -c '{cpu, ram_mb}' <<<"$TARGET")
  CHECK=$(api POST "$VM/actions/resize/precheck" "$SHAPE")
  jq '{decision, requires_stop, reasons, warnings}' <<<"$CHECK"

  # 3. Apply only when asked to, and only when the precheck allows it.
  if [[ "${RESIZE:-}" == "1" && "$(jq -r .decision <<<"$CHECK")" != "blocked" ]]; then
    STOP=$(jq -r .requires_stop <<<"$CHECK")
    [[ "$STOP" == "true" ]] && wait_for "$(api POST "$VM/actions/stop" '{}' "$(key stop)" | jq -r .operation_id)"
    wait_for "$(api PATCH "$VM/actions/resize-plan" "$SHAPE" "$(key resize)" | jq -r .operation_id)"
    [[ "$STOP" == "true" ]] && wait_for "$(api POST "$VM/actions/start" '{}' "$(key start)" | jq -r .operation_id)"
  fi
fi

# 4. Add an SSH public key to the admin user.
if [[ -n "${IBEE_SSH_PUBLIC_KEY:-}" ]]; then
  BODY=$(jq -n --arg key "$IBEE_SSH_PUBLIC_KEY" '{ssh_key_mode: "add", ssh_keys: [$key]}')
  wait_for "$(api PATCH "$VM/actions/access" "$BODY" "$(key access)" | jq -r .operation_id)"
fi

# 5. A short-lived browser console. The URL grants access: do not log or share it.
api POST /compute/console/sessions "$(jq -n --arg vm "$IBEE_VM_ID" '{vm_id: $vm, vm_type: "cloud"}')" | jq -r .connect_url
