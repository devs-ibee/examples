#!/usr/bin/env bash
# Cloud VM lifecycle with plain HTTP calls: create, wait, stop, start, delete.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev,
#              IBEE_SITE_ID, IBEE_SSH_KEY_ID, KEEP=1
# IBEE_API_URL overrides the API base URL.
set -euo pipefail

if [[ "${IBEE_ENV:-}" == "dev" ]]; then API="https://api.ibee.co.in/v1"; else API="https://api.ibee.ai/v1"; fi
API="${IBEE_API_URL:-$API}"

# api METHOD PATH [JSON_BODY] [EXTRA_HEADER]
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
  for _ in $(seq 1 180); do
    op=$(api GET "/compute/operations/$operation_id")
    status=$(jq -r .status <<<"$op")
    case "$status" in
      succeeded) echo "  $(jq -r .action <<<"$op"): succeeded"; return 0 ;;
      failed | cancelled | timed_out) echo "  operation $operation_id $status: $(jq -r '.error_message // ""' <<<"$op")" >&2; return 1 ;;
    esac
    echo "  $(jq -r .action <<<"$op"): $status"
    sleep 10
  done
  echo "operation $operation_id did not finish" >&2
  return 1
}

# 1. Site, cheapest priced plan, and an Ubuntu image.
SITE_ID="${IBEE_SITE_ID:-$(api GET /compute/sites | jq -r '.sites[0].site_id')}"
PLAN=$(api GET "/compute/plans?vm_type=cloud&site_id=$SITE_ID" |
  jq -c '[.plans[] | select(.selectable and .pricing_status == "priced")] | sort_by(.hourly_price_minor // 0) | .[0]')
IMAGE=$(api GET "/compute/images?vm_type=cloud&site_id=$SITE_ID" |
  jq -c '(.images | map(select(.os_distro == "ubuntu")) | .[0]) // .images[0]')
echo "Plan $(jq -r .name <<<"$PLAN") with image $(jq -r .name <<<"$IMAGE") at site $SITE_ID"

# 2. Create. billing_catalog is copied unchanged from the chosen plan.
NAME="example-vm-$RANDOM"
BODY=$(jq -n --arg name "$NAME" --arg site "$SITE_ID" --arg key "${IBEE_SSH_KEY_ID:-}" \
  --argjson plan "$PLAN" --argjson image "$IMAGE" '{
    name: $name,
    site_id: $site,
    plan_id: $plan.plan_id,
    template_id: $image.template_id,
    os_distro: $image.os_distro,
    os_type: $image.os_type,
    cpu: $plan.cpu,
    ram_mb: $plan.ram_mb,
    disk_gb: $plan.disk_gb,
    ssh_key_ids: (if $key == "" then [] else [$key] end),
    tags: ["example"],
    billing_catalog: $plan.billing_catalog
  }')
ACCEPTED=$(api POST /compute/cloud-vms "$BODY" "X-Idempotency-Key: create-$NAME")
VM_ID=$(jq -r .vm_id <<<"$ACCEPTED")
echo "Creating $NAME ($VM_ID)"
wait_for "$(jq -r .operation_id <<<"$ACCEPTED")"
api GET "/compute/cloud-vms/$VM_ID" | jq '{name, status, public_ip, private_ip}'

# 3. Power actions.
echo "Stopping"
wait_for "$(api POST "/compute/cloud-vms/$VM_ID/actions/stop" '{}' "X-Idempotency-Key: stop-$VM_ID-$RANDOM" | jq -r .operation_id)"
echo "Starting"
wait_for "$(api POST "/compute/cloud-vms/$VM_ID/actions/start" '{}' "X-Idempotency-Key: start-$VM_ID-$RANDOM" | jq -r .operation_id)"

# 4. Delete and release the automatic public IP ("reserve" keeps it as a Reserved IP).
if [[ "${KEEP:-}" == "1" ]]; then
  echo "Keeping $VM_ID"
else
  echo "Deleting"
  wait_for "$(api DELETE "/compute/cloud-vms/$VM_ID" '{"public_ip_action": "release"}' "X-Idempotency-Key: delete-$VM_ID" | jq -r .operation_id)"
fi
