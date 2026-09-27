#!/usr/bin/env bash
# GPU VM lifecycle with plain HTTP calls: create from a GPU plan, wait, delete.
#
# Requires: curl, jq
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev, IBEE_SITE_ID,
#              IBEE_GPU_MODEL, IBEE_SSH_KEY_ID, KEEP=1. IBEE_API_URL overrides the API base URL.
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

# 1. The first site with a priced GPU plan (or IBEE_SITE_ID), and its cheapest plan.
gpu_plans() {
  api GET "/compute/plans?vm_type=gpu&site_id=$1" |
    jq -c '[.plans[] | select(.selectable and .pricing_status == "priced" and .gpu_count > 0)] | sort_by(.hourly_price_minor // 0)'
}
SITES="${IBEE_SITE_ID:-$(api GET /compute/sites | jq -r '.sites[].site_id')}"
for SITE_ID in $SITES; do
  PLANS=$(gpu_plans "$SITE_ID")
  [[ "$(jq length <<<"$PLANS")" -gt 0 ]] && break
done
if [[ "$(jq length <<<"$PLANS")" -eq 0 ]]; then
  echo "No priced GPU plans are available to this workspace. Contact support for GPU access." >&2
  exit 1
fi
PLAN=$(jq -c '.[0]' <<<"$PLANS")
GPU_MODEL=$(jq -r --arg fallback "${IBEE_GPU_MODEL:-}" '.gpu_model // $fallback' <<<"$PLAN")
[[ -n "$GPU_MODEL" ]] || { echo "The plan does not report its GPU model; set IBEE_GPU_MODEL" >&2; exit 1; }
IMAGE=$(api GET "/compute/images?vm_type=gpu&site_id=$SITE_ID" |
  jq -c '(.images | map(select(.gpu_compatible and .os_distro == "ubuntu")) | .[0]) // .images[0]')
echo "$(jq -r .name <<<"$PLAN"): $(jq -r .gpu_count <<<"$PLAN") x $GPU_MODEL at site $SITE_ID"

# 2. Create. billing_catalog is copied unchanged from the chosen plan.
NAME="example-gpu-$RANDOM"
BODY=$(jq -n --arg name "$NAME" --arg site "$SITE_ID" --arg model "$GPU_MODEL" --arg key "${IBEE_SSH_KEY_ID:-}" \
  --argjson plan "$PLAN" --argjson image "$IMAGE" '{
    name: $name, site_id: $site, plan_id: $plan.plan_id,
    template_id: $image.template_id, os_distro: $image.os_distro, os_type: "linux",
    cpu: $plan.cpu, ram_mb: $plan.ram_mb, disk_gb: $plan.disk_gb,
    gpu_count: $plan.gpu_count, gpu_model: $model,
    ssh_key_ids: (if $key == "" then [] else [$key] end),
    tags: ["example", "gpu"],
    billing_catalog: $plan.billing_catalog
  }')
ACCEPTED=$(api POST /compute/gpu-vms "$BODY" "X-Idempotency-Key: create-$NAME")
VM_ID=$(jq -r .vm_id <<<"$ACCEPTED")
echo "Creating $NAME ($VM_ID)"
wait_for "$(jq -r .operation_id <<<"$ACCEPTED")"
api GET "/compute/gpu-vms/$VM_ID" | jq '{name, status, gpu_count, gpu_model, public_ip}'

# 3. Delete and release the automatic public IP.
if [[ "${KEEP:-}" != "1" ]]; then
  wait_for "$(api DELETE "/compute/gpu-vms/$VM_ID" '{"public_ip_action": "release"}' "X-Idempotency-Key: delete-$VM_ID" | jq -r .operation_id)"
fi
