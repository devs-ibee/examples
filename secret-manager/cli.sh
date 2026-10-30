#!/usr/bin/env bash
# Store a secret, update it, read its versions, and delete it, with the ibee CLI.
set -euo pipefail

STORE_ID=$(ibee -o id secrets stores create --name example-app --description "Example application settings")
SECRET_ID=$(ibee -o id secrets create "$STORE_ID" --secret-name database \
  --value '{"USER": "app", "PASSWORD": "change-me"}')

ibee secrets set-value "$SECRET_ID" --value '{"USER": "app", "PASSWORD": "changed"}'
ibee secrets versions "$SECRET_ID"
ibee secrets value "$SECRET_ID"

ibee secrets delete-permanent "$SECRET_ID" --yes
ibee secrets stores delete-permanent "$STORE_ID" --yes
