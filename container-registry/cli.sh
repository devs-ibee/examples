#!/usr/bin/env bash
# Create a registry and a push token, list its repositories, and clean up, with the ibee CLI.
set -euo pipefail

NAME="$IBEE_REGISTRY_NAME" # global and never reused
ibee registries name-check "$NAME"
REGISTRY_ID=$(ibee -o id registries create "$NAME" --sku "$IBEE_REGISTRY_SKU")
while [ "$(ibee --json registries get "$REGISTRY_ID" | jq -r .observed_state)" = PROVISIONING ]; do
  sleep 5
done

# The secret is printed only here (-o json): keep it out of logs and shell history.
TOKEN=$(ibee --json registries tokens create "$REGISTRY_ID" example-push --permission PULL_PUSH --expires-in-days 1)
TOKEN_ID=$(jq -r .token_id <<<"$TOKEN")
echo "docker login registry.ibee.ai --username '$(jq -r .username <<<"$TOKEN")' --password-stdin"

ibee registries repositories list "$REGISTRY_ID"

ibee registries tokens revoke "$REGISTRY_ID" "$TOKEN_ID" --yes
ibee registries delete "$REGISTRY_ID" --confirm-name "$NAME" --yes # must be empty
