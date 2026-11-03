#!/usr/bin/env bash
# Create a GPU VM, read it, and delete it with the ibee CLI.
set -euo pipefail

# Poll a VM operation until it finishes.
wait_op() {
  while true; do
    op=$(ibee --json ops get "$1")
    case $(jq -r .status <<<"$op") in
      succeeded | failed | cancelled | timed_out) jq -r '"\(.action): \(.status) \(.error_message // "")"' <<<"$op"; return ;;
    esac
    sleep 15
  done
}

# The request carries the plan's size and GPUs and the image's OS, so read both first.
read -r CPU RAM_MB DISK_GB GPU_COUNT GPU_MODEL < <(ibee --json compute plans --vm-type gpu --site-id "$IBEE_SITE_ID" |
  jq -r --arg id "$IBEE_GPU_PLAN_ID" '.plans[] | select(.plan_id == $id) | "\(.cpu) \(.ram_mb) \(.disk_gb) \(.gpu_count) \(.gpu_model)"')
read -r OS_DISTRO < <(ibee --json compute images --vm-type gpu --site-id "$IBEE_SITE_ID" |
  jq -r --arg id "$IBEE_GPU_TEMPLATE_ID" '.images[] | select(.template_id == $id) | .os_distro')

# --billing-interval HOURLY sends the plan's billing_catalog with its HOURLY option merged in.
CREATED=$(ibee --json gpus create --name example-gpu --site-id "$IBEE_SITE_ID" \
  --plan-id "$IBEE_GPU_PLAN_ID" --cpu "$CPU" --ram-mb "$RAM_MB" --disk-gb "$DISK_GB" \
  --gpu-count "$GPU_COUNT" --gpu-model "$GPU_MODEL" \
  --template-id "$IBEE_GPU_TEMPLATE_ID" --os-type linux --os-distro "$OS_DISTRO" \
  --billing-interval HOURLY)
wait_op "$(jq -r .operation_id <<<"$CREATED")"
VM_ID=$(jq -r .vm_id <<<"$CREATED")

ibee gpus get "$VM_ID"
wait_op "$(ibee --json gpus delete "$VM_ID" --public-ip-action release --yes | jq -r .operation_id)"
