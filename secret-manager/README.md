# Secret Manager

`api.sh` checks Secret Manager in a workspace with the IBEE API: its status (namespace and address), the names in a folder, and a search. The IBEE API never returns a secret value.

`vault.sh` and `read_secret.py` sign in with an app credential and read a secret over the Vault API at the workspace's address, with the `bao` CLI and Python (`hvac`). `vault.sh` also writes a new version with check-and-set.

```bash
bash api.sh              # IBEE API with curl and jq

export VAULT_ADDR=https://secrets.ibee.ai     # Secret Manager → Connect
export VAULT_NAMESPACE=acme-payments           # your workspace's namespace
export ROLE_ID=... SECRET_ID=...               # an app credential
bash vault.sh            # bao CLI (or vault: set BAO=vault)
pip install hvac && python3 read_secret.py
```

Set `SECRET_PATH` to read another secret (default `payments/db`). `vault.sh` writes, so it needs a **Read & write** app credential; `read_secret.py` needs only **Read only**.

Token scope for `api.sh`: `secret-manager.read`. Guides: [Secret Manager](https://ibee.ai/docs/tools/secret-manager).

## With the SDKs and CLI (0.10)

`main.py`, `index.ts` and `cli.sh` create a secret's entry at `apps/example/db` with its type and tags, read its metadata and folder, create an app credential that can read the folder, then revoke it and delete the entry.

```bash
export IBEE_SECRET_NAMESPACE=acme-apps   # only read when Secret Manager is not on for the workspace yet

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

Token scopes: `secret-manager.read`, `secret-manager.write`.
