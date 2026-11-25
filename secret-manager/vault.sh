#!/usr/bin/env bash
# Sign in with an app credential, read a secret, and save a new version with check-and-set, using the bao CLI.
# Needs VAULT_ADDR, VAULT_NAMESPACE, ROLE_ID and SECRET_ID (a Read & write app credential for the write).
set -euo pipefail

BAO="${BAO:-bao}"                 # or: BAO=vault
SECRET_PATH="${SECRET_PATH:-payments/db}"

# Logins aren't billed; the token lasts 1 hour and renews for up to 24 hours.
VAULT_TOKEN="$("$BAO" write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")"
export VAULT_TOKEN

# Every read is one billed operation.
"$BAO" kv get -mount=secret "$SECRET_PATH"
current="$("$BAO" kv metadata get -mount=secret -format=json "$SECRET_PATH" | jq -r '.data.current_version')"

# Replace the current version only if nobody saved a newer one (check-and-set).
"$BAO" kv patch -mount=secret -cas="$current" "$SECRET_PATH" rotated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
"$BAO" kv get -mount=secret -field=rotated_at "$SECRET_PATH"

# Give the token up when you're done.
"$BAO" token revoke -self
