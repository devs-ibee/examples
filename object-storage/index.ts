/**
 * Object Storage: a private bucket plus an access key scoped to that bucket.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx object-storage/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev,
 *              IBEE_STORAGE_REGION (default in-south-2), IBEE_BUCKET_NAME, KEEP=1
 */
import { randomUUID } from "node:crypto";
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});

// 1. A private bucket.
const bucketName = process.env.IBEE_BUCKET_NAME ?? `example-${randomUUID().slice(0, 8)}`;
const bucket = await client.objectStorage.createBucket({
  workspaceId,
  name: bucketName,
  region: process.env.IBEE_STORAGE_REGION ?? "in-south-2",
  isPublic: false,
  tags: ["example"],
});
console.log(`Bucket ${bucketName} in ${bucket.region}`);

// 2. An access key that can only read and write objects in this bucket.
const key = await client.objectStorage.createS3Credential({
  workspaceId,
  name: `${bucketName}-app`,
  permissionType: "object_rw",
  bucketScope: "specific",
  allowedBuckets: [bucketName],
});
console.log(`Access key ID:     ${key.access_key_id}`);
console.log(`Secret access key: ${key.secret_access_key}   (shown only once; store it now)`);
console.log(`S3 endpoint:       https://${workspaceId}.blob.ibeestorage.com`);

// 3. Clean up. A bucket must be empty before it can be deleted.
if (process.env.KEEP !== "1") {
  await client.objectStorage.revokeS3Credential({ workspaceId, accessKeyId: key.access_key_id });
  await client.objectStorage.deleteBucket({ workspaceId, bucketName });
  console.log("Revoked the access key and deleted the bucket");
}
