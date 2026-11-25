// Create a secret's entry and an app login for it, read them, and delete both.
// The IBEE API never takes or returns a secret value: write and read values at
// the workspace's Vault address with bao or vault (see README.md).
import { Ibee, NotFoundError } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const sm = ibee.secretManager;
const secret_path = "apps/example/db";
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Turn Secret Manager on once per workspace. This is permanent and the namespace never changes.
async function workspace() {
  try {
    return await sm.getSecretManagerWorkspace();
  } catch (error) {
    if (!(error instanceof NotFoundError)) throw error;
  }
  let op = await sm.enableSecretManagerWorkspace({ namespace: process.env.IBEE_SECRET_NAMESPACE! });
  while (op.status !== "completed" && op.status !== "failed") {
    await sleep(5_000);
    op = await sm.getSecretManagerOperation({ operation_id: op.id });
  }
  if (op.status === "failed") throw new Error(`Secret Manager was not enabled: ${op.error_code}`);
  return sm.getSecretManagerWorkspace();
}
const ws = await workspace();
console.log(`Secret Manager namespace ${ws.namespace} (${ws.state}), Vault address ${ws.endpoint}`);

// The entry holds the secret's type and tags; the type is fixed once created.
const { types } = (await sm.listSecretManagerSecretTypes()) as { types: { id: string }[] };
console.log("types:", types.map((t) => t.id));
await sm.updateSecretManagerSecretMetadata({
  secret_path,
  custom_metadata: { ibee_type: "database_credentials", owner: "example" },
  max_versions: 10,
});
const meta = (await sm.getSecretManagerSecretMetadata({ secret_path })) as {
  custom_metadata: Record<string, string>;
  current_version: number;
  versions: Record<string, unknown>;
};
const versions = Object.keys(meta.versions).length;
console.log(`${secret_path}: ${meta.custom_metadata.ibee_type}, version ${meta.current_version}, ${versions} versions`);
const listing = (await sm.listSecretManagerSecrets({ prefix: "apps/example" })) as { keys: string[] };
console.log("apps/example holds:", listing.keys);

// An AppRole login that can read apps/example. Its secret ID is shown once.
type Credential = { id: string; state: string };
const created = (await sm.createSecretManagerAppCredential({
  name: "example-app",
  access: "read",
  folder: "apps/example",
})) as { credential: Credential };
const credential_id = created.credential.id;
while (((await sm.getSecretManagerAppCredential({ credential_id })) as Credential).state !== "active") {
  await sleep(5_000);
}
const login = (await sm.issueSecretManagerAppCredentialSecretId({ credential_id })) as Record<string, string>;
console.log(`AppRole role ID ${login.role_id} in namespace ${login.namespace}; login.secret_id is returned only now`);

// Revoking stops new sign-ins at once; deleting the secret removes every version of its value.
await sm.revokeSecretManagerAppCredential({ credential_id });
await sm.deleteSecretManagerSecret({ secret_path });
