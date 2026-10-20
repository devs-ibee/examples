// Create a registry and a push token, list its repositories, and clean up.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const registries = ibee.containerRegistry;
const name = process.env.IBEE_REGISTRY_NAME!; // global and never reused
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

console.log(await registries.checkContainerRegistryNameAvailability({ registry_name: name }));
let registry = await registries.createContainerRegistry({
  registry_name: name,
  confirm_registry_name: name,
  billing_catalog: { sku_code: process.env.IBEE_REGISTRY_SKU! },
});
const registry_id = registry.registry_id;
while (registry.observed_state === "PROVISIONING") {
  // 202 while it is set up
  await sleep(5_000);
  registry = await registries.getContainerRegistry({ registry_id });
}
console.log(`registry.ibee.ai/${registry.registry_name}: ${registry.observed_state}`);

// The secret is returned only here: hand it to `docker login --password-stdin` (push.sh).
const token = await registries.createContainerRegistryAccessToken({
  registry_id,
  token_name: "example-push",
  permission: "PULL_PUSH",
  expires_in_days: 1,
});
console.log(`docker login registry.ibee.ai --username '${token.username}' --password-stdin`);

const repositories = await registries.listContainerRegistryRepositories({ registry_id });
console.log(`${repositories.total} repositories`);

await registries.revokeContainerRegistryAccessToken({ registry_id, token_id: token.token_id });
await registries.deleteContainerRegistry({ registry_id, confirm_registry_name: name }); // must be empty
