#!/usr/bin/env bash
# Block Storage with plain HTTP calls: create, attach to a VM, grow, detach, delete.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, IBEE_SITE_ID,
#              optional IBEE_BLOCK_SKU, IBEE_ENV=dev, KEEP=1. IBEE_API_URL overrides the API base URL.
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

# Wait until a volume reaches one of the given states.
wait_volume() {
  local volume_id="$1" states="$2" state
  for _ in $(seq 1 180); do
    state=$(api GET "/block-storage/volumes/$volume_id" | jq -r .state)
    [[ " $states " == *" $state "* ]] && return 0
    [[ "$state" == "error" ]] && { echo "volume $volume_id is in error" >&2; return 1; }
    sleep 5
  done
  echo "volume $volume_id is still $state" >&2
  return 1
}

# 1. Create a volume at the VM's site.
BODY=$(jq -n --arg name "example-data-$RANDOM" --arg site "$IBEE_SITE_ID" --arg sku "${IBEE_BLOCK_SKU:-}" '
  {name: $name, size_gb: 20, site_id: $site, volume_class: "balanced"}
  + (if $sku == "" then {} else {sku_code: $sku} end)')
VOLUME_ID=$(api POST /block-storage/volumes "$BODY" | jq -r .volume.id)
wait_volume "$VOLUME_ID" "ready in-use"
echo "Volume $VOLUME_ID is ready"

# 2. Attach it to the VM, then record that you reviewed the mount instructions.
ATTACH=$(jq -n --arg id "$VOLUME_ID" '{volume_id: $id}')
wait_for "$(api POST "$VM/actions/attach-volume" "$ATTACH" "X-Idempotency-Key: attach-$VOLUME_ID" | jq -r .operation_id)"
api POST "$VM/mount-guidance/acknowledge" "$ATTACH" >/dev/null

# 3. Grow to 30 GB. Run resize2fs inside the VM afterwards.
api POST "/block-storage/volumes/$VOLUME_ID/resize" '{"new_size_gb": 30, "vm_state": "running", "allow_online": true}' >/dev/null
wait_volume "$VOLUME_ID" "ready in-use"

# 4. Unmount inside the VM first, then detach and delete.
if [[ "${KEEP:-}" != "1" ]]; then
  DETACH=$(jq -n --arg id "$VOLUME_ID" '{volume_id: $id, confirm_unmounted: true}')
  wait_for "$(api POST "$VM/actions/detach-volume" "$DETACH" "X-Idempotency-Key: detach-$VOLUME_ID" | jq -r .operation_id)"
  wait_volume "$VOLUME_ID" "ready"
  api DELETE "/block-storage/volumes/$VOLUME_ID" >/dev/null
  echo "Deleted $VOLUME_ID"
fi
