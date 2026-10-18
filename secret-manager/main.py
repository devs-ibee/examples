"""Store a secret, update it, read its versions, and delete it."""

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
vault = client.secret_store

store = vault.create_secret_store(name="example-app", description="Example application settings")
secret = vault.create_secret(store.id, secret_name="database", value={"USER": "app", "PASSWORD": "change-me"})

# Every update is a new version; roll back with rollback_secret.
vault.update_secret_value(secret.id, value={"USER": "app", "PASSWORD": "changed"})
versions = vault.list_secret_versions(secret.id)
print(f"{versions.secret_name}: current version {versions.current_version}")
print(f"keys: {sorted(vault.get_secret_value(secret.id).data)}")

vault.permanently_delete_secret(secret.id)
vault.permanently_delete_secret_store(store.id)
