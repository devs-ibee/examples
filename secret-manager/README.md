# Secret Manager

Keep application secrets out of code: store them in a Secret Manager store, update them with versioning and rollback, and give an application its own read-only AppRole identity.

## What it does

1. Creates the store `example-payments`.
2. Creates the secret `stripe` with two keys, then reads the value back.
3. Writes a new version, lists the versions, and rolls back to version 1.
4. Creates a read-only AppRole identity for an application and fetches its role ID and secret ID.
5. Permanently deletes the secret, the identity, and the store. Set `KEEP=1` to keep them.

## Requirements

- An API token with `secret-store.read` and `secret-store.write`.
- A verified organization. Secret Manager requires identity verification.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
bash api.sh          # curl and jq
```

The examples generate random placeholder values. In real use, read secret values from a file or your terminal, never from source code.

## Tokens and identities

- **Your API token** manages stores, secrets, and identities through the public API.
- **An application identity** is what a running workload uses. AppRole identities (for VMs, servers, and scripts) sign in with a role ID and secret ID. Kubernetes identities are bound to a namespace and service account. Each identity is `read_only` or `read_write`.

Fetching an AppRole identity's access details generates a fresh secret ID. Treat it like a password: deliver it to the workload through your deployment tooling and do not log it.
