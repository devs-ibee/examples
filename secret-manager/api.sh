#!/usr/bin/env bash
# Secret Manager through the IBEE API with curl: status, names and search. No call returns a value.
set -euo pipefail

API="${IBEE_API_URL:-https://api.ibee.ai/v1}"   # https://api.ibee.co.in/v1 for development
auth=(-H "Authorization: Bearer $IBEE_TOKEN")
ws="workspace_id=$IBEE_WORKSPACE_ID"
SECRET_PATH="${SECRET_PATH:-payments/db}"
FOLDER="${SECRET_PATH%/*}/"

# The namespace and address your applications use (404 workspace_not_enabled until you enable it).
curl -sS --fail-with-body "${auth[@]}" "$API/secret-manager/workspace?$ws" \
  | jq '{namespace, state, endpoint, max_versions}'

# Names in a folder: folders end in "/".
curl -sS --fail-with-body "${auth[@]}" "$API/secret-manager/secrets?$ws&prefix=$FOLDER" | jq '.keys'

# Search by part of a name or path; pass next_cursor back as cursor for the next page.
curl -sS --fail-with-body "${auth[@]}" "$API/secret-manager/catalog?$ws&query=db&limit=10" \
  | jq '{items, next_cursor}'
