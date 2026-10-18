# Secret Manager

Create a store and a secret with two keys, write a new version, read the versions and the current value, then delete both permanently.

```bash
python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

Applications read secrets with an identity (AppRole or Kubernetes) scoped to a store: see `create_secret_identity` and `create_secret_identity_scope` (`ibee secrets identities`). Permanent deletion cannot be undone; `delete_secret` is the soft delete.

Token scopes: `secret-store.read`, `secret-store.write`.
