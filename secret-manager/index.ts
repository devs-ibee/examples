// Store a secret, update it, read its versions, and delete it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const vault = ibee.secretStore;

const store = await vault.createSecretStore({ name: "example-app", description: "Example application settings" });
const secret = await vault.createSecret({
  store_id: store.id!,
  secret_name: "database",
  value: { USER: "app", PASSWORD: "change-me" },
});
const secret_id = secret.id!;

// Every update is a new version; roll back with rollbackSecret.
await vault.updateSecretValue({ secret_id, value: { USER: "app", PASSWORD: "changed" } });
const versions = await vault.listSecretVersions({ secret_id });
console.log(`${versions.secret_name}: current version ${versions.current_version}`);
console.log(`keys: ${Object.keys((await vault.getSecretValue({ secret_id })).data ?? {}).sort()}`);

await vault.permanentlyDeleteSecret({ secret_id });
await vault.permanentlyDeleteSecretStore({ store_id: store.id! });
