/**
 * CDN in front of a bucket: SPA routing, custom domain, purge, and signed URLs.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx cdn/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_BUCKET_NAME,
 *              optional IBEE_DOMAIN, IBEE_ENV=dev, KEEP=1
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const bucket = process.env.IBEE_BUCKET_NAME!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});
const cdn = client.cdn;

// 1. A distribution in front of the bucket.
const distribution = await cdn.createDistribution({
  workspaceId,
  name: `${bucket}-site`,
  origin_type: "bucket",
  origin_id: bucket,
  cache_policy: "static-assets",
});
const distributionId = distribution.id;
console.log(`Distribution ${distributionId} is ${distribution.status}: ${distribution.default_url}`);

// 2. Single-page-app routing: unknown paths return index.html.
await cdn.updateWebsiteConfig({ workspaceId, distributionId, request: { index_document: "index.html" } });

// 3. Your own domain. Create the DNS record from the instructions, then verify.
if (process.env.IBEE_DOMAIN) {
  const domain = await cdn.createCustomDomain({ workspaceId, distributionId, domain: process.env.IBEE_DOMAIN });
  console.log(`${domain.domain} is ${domain.status}. Create this DNS record:`);
  for (const line of domain.instructions ?? []) console.log("  ", line);
  const check = await cdn.verifyCustomDomain({ workspaceId, distributionId, domain: domain.domain });
  console.log(`Verification: ${check.status} ${check.message}`);
}

// 4. After each deploy, purge the files that changed.
const purge = await cdn.purgeCache({ workspaceId, distributionId, request: { mode: "url", paths: ["/index.html"] } });
console.log(`Purge ${purge.success ? "started" : "failed"}: ${purge.purged ?? []}`);

// 5. A signed CDN link for one object, valid for one hour.
const link = await cdn.generateUrl({ workspaceId, bucket_name: bucket, object_key: "index.html", expires_in: 3600 });
console.log(`Signed URL: ${link.cdn_url}`);

if (process.env.KEEP !== "1") {
  await cdn.deleteDistribution({ workspaceId, distributionId });
  console.log(`Deleted ${distributionId}`);
}
