"""Create a secret's entry and an app login for it, read them, and delete both.

The IBEE API never takes or returns a secret value: write and read values at
the workspace's Vault address with bao or vault (see README.md).
"""

import os
import time

from ibee import Ibee, NotFoundError

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
sm = client.secret_manager
PATH = "apps/example/db"

# Turn Secret Manager on once per workspace. This is permanent and the namespace never changes.
try:
    workspace = sm.get_secret_manager_workspace()
except NotFoundError:
    op = sm.enable_secret_manager_workspace(namespace=os.environ["IBEE_SECRET_NAMESPACE"])
    while op.status not in ("completed", "failed"):
        time.sleep(5)
        op = sm.get_secret_manager_operation(op.id)
    if op.status == "failed":
        raise SystemExit(f"Secret Manager was not enabled: {op.error_code}")
    workspace = sm.get_secret_manager_workspace()
print(f"Secret Manager namespace {workspace.namespace} ({workspace.state}), Vault address {workspace.endpoint}")

# The entry holds the secret's type and tags; the type is fixed once created.
print("types:", [t["id"] for t in sm.list_secret_manager_secret_types()["types"]])
sm.update_secret_manager_secret_metadata(
    PATH,
    custom_metadata={"ibee_type": "database_credentials", "owner": "example"},
    max_versions=10,
)
meta = sm.get_secret_manager_secret_metadata(PATH)
print(f"{PATH}: {meta['custom_metadata']['ibee_type']}, version {meta['current_version']}, {len(meta['versions'])} versions")
print("apps/example holds:", sm.list_secret_manager_secrets(prefix="apps/example")["keys"])

# An AppRole login that can read apps/example. Its secret ID is shown once.
created = sm.create_secret_manager_app_credential(name="example-app", access="read", folder="apps/example")
credential_id = created["credential"]["id"]
while sm.get_secret_manager_app_credential(credential_id)["state"] != "active":
    time.sleep(5)
login = sm.issue_secret_manager_app_credential_secret_id(credential_id)
print(f"AppRole role ID {login['role_id']} in namespace {login['namespace']}; login['secret_id'] is returned only now")

# Revoking stops new sign-ins at once; deleting the secret removes every version of its value.
sm.revoke_secret_manager_app_credential(credential_id)
sm.delete_secret_manager_secret(PATH)
