#!/usr/bin/env bash
# Secret Manager with the ibee CLI: a store, a versioned secret, rollback, and an AppRole identity.
#
# Requires: pip install ibee-cli, jq, openssl
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev, KEEP=1
set -euo pipefail

STORE_ID=$(ibee --json secrets stores create example-payments -d "Payment provider keys" | jq -r .id)

VALUE=$(jq -cn --arg key "sk_test_$(openssl rand -hex 12)" --arg hook "whsec_$(openssl rand -hex 12)" \
  '{API_KEY: $key, WEBHOOK_SECRET: $hook}')
SECRET_ID=$(ibee --json secrets create --store-id "$STORE_ID" --name stripe --value "$VALUE" | jq -r .id)
ibee --json secrets value "$SECRET_ID" | jq '.data | keys'

# A new version, then roll back to version 1.
ibee secrets set-value "$SECRET_ID" --value "$(jq -c --arg key "sk_test_$(openssl rand -hex 12)" '.API_KEY = $key' <<<"$VALUE")"
ibee secrets versions "$SECRET_ID"
ibee secrets rollback "$SECRET_ID" --version 1

# A read-only AppRole identity. `identities access --show-sensitive` prints a fresh secret ID.
IDENTITY_ID=$(ibee --json secrets identities create --store-id "$STORE_ID" --name payments-api \
  --auth-method approle --token-policy-mode read_only | jq -r .id)
ibee secrets identities get "$IDENTITY_ID"

if [[ "${KEEP:-}" != "1" ]]; then
  ibee secrets delete-permanent "$SECRET_ID" --yes
  ibee secrets identities delete "$IDENTITY_ID" --yes
  ibee secrets stores delete-permanent "$STORE_ID" --yes
fi
