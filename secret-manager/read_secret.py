"""Sign in to Secret Manager with an app credential and read a secret over the Vault API (hvac)."""

import os

import hvac

client = hvac.Client(url=os.environ["VAULT_ADDR"], namespace=os.environ["VAULT_NAMESPACE"])
client.auth.approle.login(role_id=os.environ["ROLE_ID"], secret_id=os.environ["SECRET_ID"])

path = os.environ.get("SECRET_PATH", "payments/db")
# Read once and keep the values: every read is a billed operation.
secret = client.secrets.kv.v2.read_secret_version(path=path, mount_point="secret", raise_on_deleted_version=True)
values = secret["data"]["data"]
print(f"{path} v{secret['data']['metadata']['version']}: keys {sorted(values)}")

client.auth.token.revoke_self()
