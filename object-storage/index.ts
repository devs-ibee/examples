// Create a private bucket and an S3 access key for it, then delete both.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const storage = ibee.objectStorage;

const bucket = await storage.createBucket({
  name: process.env.IBEE_BUCKET_NAME!,
  region: process.env.IBEE_STORAGE_REGION!,
});
console.log(`Bucket ${bucket.name} in ${bucket.region}`);

// An access key that can read and write objects in this bucket only.
const key = await storage.createS3Credential({
  name: `${bucket.name}-app`,
  permission_type: "object_rw",
  bucket_scope: "specific",
  allowed_buckets: [bucket.name],
});
console.log(`Access key ${key.access_key_id} (the secret key is shown only once)`);

for (const item of (await storage.listBuckets()).buckets ?? []) {
  console.log(`  ${item.name}  ${item.object_count} objects`);
}

await storage.revokeS3Credential({ access_key_id: key.access_key_id });
await storage.deleteBucket({ bucket_name: bucket.name }); // a bucket must be empty to delete it
