/**
 * Secret Manager: a store, a versioned secret, rollback, and an AppRole identity.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx secret-manager/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev, KEEP=1
 */
import { randomBytes } from "node:crypto";
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const vault = client.secretStore;
const placeholder = (prefix: string) => `${prefix}${randomBytes(12).toString("hex")}`;

const store = await vault.createSecretStore({ workspaceId, name: "example-payments", description: "Payment provider keys" });
const storeId = store.id!;

const webhookSecret = placeholder("whsec_");
const secret = await vault.createSecret({
  workspaceId,
  storeId,
  name: "stripe",
  value: { API_KEY: placeholder("sk_test_"), WEBHOOK_SECRET: webhookSecret },
});
const secretId = secret.id!;
const current = await vault.getSecretValue({ workspaceId, secretId });
console.log(`Secret ${current.secret_name} has keys ${Object.keys(current.data ?? {}).sort().join(", ")}`);

// Every update is a new version; roll back if a rotation goes wrong.
await vault.updateSecretValue({
  workspaceId,
  secretId,
  value: { API_KEY: placeholder("sk_test_"), WEBHOOK_SECRET: webhookSecret }, // replaces all keys
});
const versions = await vault.listSecretVersions({ workspaceId, secretId });
console.log(`Current version ${versions.current_version}`);
await vault.rollbackSecret({ workspaceId, secretId, version: 1 });

// A read-only AppRole identity for the application.
const identity = await vault.createSecretIdentity({
  workspaceId,
  storeId,
  authMethod: "approle",
  name: "payments-api",
  tokenPolicyMode: "read_only",
});
const access = await vault.getSecretIdentityAccess({ workspaceId, identityId: identity.id });
console.log(`Identity ${identity.name}: role ID ${access.role_id}; a new secret ID was issued (not printed)`);

if (process.env.KEEP !== "1") {
  await vault.permanentlyDeleteSecret({ workspaceId, secretId });
  await vault.deleteSecretIdentity({ workspaceId, identityId: identity.id });
  await vault.permanentlyDeleteSecretStore({ workspaceId, storeId });
  console.log("Deleted the secret, identity, and store");
}
