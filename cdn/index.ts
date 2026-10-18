// Put the CDN in front of a public bucket, purge a path, and delete the distribution.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV

const distribution = await ibee.cdn.createCdnDistribution({
  name: "example-site",
  origin_type: "bucket",
  origin_id: process.env.IBEE_BUCKET_NAME!,
});
const distribution_id = distribution.id;
console.log(`Distribution ${distribution_id} is ${distribution.status}: ${distribution.default_url}`);

// Serve index.html for unknown paths (single-page apps).
await ibee.cdn.updateCdnWebsiteConfig({ distribution_id, index_document: "index.html" });

// After a deploy, purge the files that changed.
const purge = await ibee.cdn.purgeCdnCache({ distribution_id, mode: "url", paths: ["/index.html"] });
console.log(`Purge succeeded: ${purge.success}`);

await ibee.cdn.deleteCdnDistribution({ distribution_id });
