#!/usr/bin/env bash
# Create a secret's entry and an app login for it, read them, and delete both, with the ibee CLI.
# The IBEE API never takes or returns a secret value: write and read values at
# the workspace's Vault address with bao or vault (see README.md).
set -euo pipefail

SECRET=apps/example/db

# Turn Secret Manager on once per workspace (exit code 14 is a 404: not enabled yet).
# This is permanent and the namespace never changes.
code=0
ibee secrets workspace get >/dev/null 2>&1 || code=$?
if [ "$code" -eq 14 ]; then
  OP_ID=$(ibee --json secrets workspace enable --namespace "$IBEE_SECRET_NAMESPACE" --yes | jq -r .id)
  until [[ $(ibee --json secrets operations get "$OP_ID" | jq -r .status) =~ ^(completed|failed)$ ]]; do sleep 5; done
elif [ "$code" -ne 0 ]; then
  exit "$code"
fi
ibee --json secrets workspace get | jq -r '"Secret Manager namespace \(.namespace) (\(.state)), Vault address \(.endpoint)"'

# The entry holds the secret's type and tags; the type is fixed once created.
ibee --json secrets types | jq -c '[.types[].id]'
ibee secrets update "$SECRET" --custom-metadata '{"ibee_type": "database_credentials", "owner": "example"}' --max-versions 10
ibee secrets get "$SECRET"
ibee secrets history "$SECRET"
ibee secrets list --prefix apps/example

# An AppRole login that can read apps/example. Its secret ID is shown once.
CREDENTIAL_ID=$(ibee --json secrets credentials create --name example-app --access read --folder apps/example |
  jq -r .credential.id)
until [ "$(ibee --json secrets credentials get "$CREDENTIAL_ID" | jq -r .state)" = active ]; do sleep 5; done
ibee --json secrets credentials secret-id "$CREDENTIAL_ID" | jq -r '"AppRole role ID \(.role_id) in namespace \(.namespace)"'

# Revoking stops new sign-ins at once; deleting the secret removes every version of its value.
ibee secrets credentials revoke "$CREDENTIAL_ID" --yes
ibee secrets delete "$SECRET" --yes
