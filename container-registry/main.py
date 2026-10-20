"""Create a registry and a push token, list its repositories, and clean up."""

import os
import time

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
registries = client.container_registry
name = os.environ["IBEE_REGISTRY_NAME"]  # global and never reused

print(registries.check_container_registry_name_availability(name))
registry = registries.create_container_registry(
    registry_name=name,
    confirm_registry_name=name,
    billing_catalog={"sku_code": os.environ["IBEE_REGISTRY_SKU"]},
)
while registry.observed_state == "PROVISIONING":  # 202 while it is set up
    time.sleep(5)
    registry = registries.get_container_registry(registry.registry_id)
print(f"registry.ibee.ai/{registry.registry_name}: {registry.observed_state}")

# The secret is returned only here: hand it to `docker login --password-stdin` (push.sh).
token = registries.create_container_registry_access_token(
    registry.registry_id, token_name="example-push", permission="PULL_PUSH", expires_in_days=1
)
print(f"docker login registry.ibee.ai --username '{token.username}' --password-stdin")

repositories = registries.list_container_registry_repositories(registry.registry_id)
print(f"{repositories.total} repositories")

registries.revoke_container_registry_access_token(registry.registry_id, token.token_id)
registries.delete_container_registry(registry.registry_id, confirm_registry_name=name)  # must be empty
