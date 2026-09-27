"""Secret Manager: a store, a versioned secret, rollback, and an AppRole identity.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (secret-store.read, secret-store.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the store, secret, and identity
"""

import os
import secrets

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
vault = client.secret_store

# 1. A store groups related secrets and the identities that can read them.
store = vault.create_secret_store(workspace_id=WORKSPACE_ID, name="example-payments", description="Payment provider keys")
print(f"Store {store.name} ({store.id}), key {store.store_key}")

# 2. A secret holds one or more key/value pairs. Placeholder values stand in for real keys.
webhook_secret = f"whsec_{secrets.token_hex(12)}"
secret = vault.create_secret(
    store_id=store.id,
    workspace_id=WORKSPACE_ID,
    secret_name="stripe",
    value={"API_KEY": f"sk_test_{secrets.token_hex(12)}", "WEBHOOK_SECRET": webhook_secret},
)
current = vault.get_secret_value(secret_id=secret.id, workspace_id=WORKSPACE_ID)
print(f"Secret {current.secret_name} has keys {sorted(current.data or {})}")

# 3. Every update is a new version; roll back if a rotation goes wrong.
vault.update_secret_value(
    secret_id=secret.id,
    workspace_id=WORKSPACE_ID,
    value={"API_KEY": f"sk_test_{secrets.token_hex(12)}", "WEBHOOK_SECRET": webhook_secret},  # replaces all keys
)
versions = vault.list_secret_versions(secret_id=secret.id, workspace_id=WORKSPACE_ID)
print(f"Current version {versions.current_version}; versions {sorted(versions.versions)}")
vault.rollback_secret(secret_id=secret.id, workspace_id=WORKSPACE_ID, version=1)
print("Rolled back to version 1")

# 4. A read-only AppRole identity for the application that uses these secrets.
identity = vault.create_secret_identity(
    store_id=store.id, workspace_id=WORKSPACE_ID, auth_method="approle", name="payments-api", token_policy_mode="read_only"
)
access = vault.get_secret_identity_access(identity_id=identity.id, workspace_id=WORKSPACE_ID)
print(f"Identity {identity.name}: role ID {access.role_id}; a new secret ID was issued (not printed)")

# 5. Clean up. Permanent deletion cannot be undone.
if os.getenv("KEEP") != "1":
    vault.permanently_delete_secret(secret_id=secret.id, workspace_id=WORKSPACE_ID)
    vault.delete_secret_identity(identity_id=identity.id, workspace_id=WORKSPACE_ID)
    vault.permanently_delete_secret_store(store_id=store.id, workspace_id=WORKSPACE_ID)
    print("Deleted the secret, identity, and store")
