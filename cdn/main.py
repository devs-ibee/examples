"""CDN in front of a bucket: SPA routing, custom domain, purge, and signed URLs.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (cdn.read, cdn.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_BUCKET_NAME   public bucket that holds the site, including index.html
  IBEE_DOMAIN        your own domain for the site (optional)
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the distribution
"""

import os

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
BUCKET = os.environ["IBEE_BUCKET_NAME"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
cdn = client.cdn

# 1. A distribution in front of the bucket.
distribution = cdn.create_cdn_distribution(
    workspace_id=WORKSPACE_ID,
    name=f"{BUCKET}-site",
    origin_type="bucket",
    origin_id=BUCKET,
    cache_policy="static-assets",
)
distribution_id = distribution["id"]
print(f"Distribution {distribution_id} is {distribution['status']}: {distribution['default_url']}")

# 2. Single-page-app routing: unknown paths return index.html.
website = cdn.update_cdn_website_config(
    distribution_id=distribution_id, workspace_id=WORKSPACE_ID, index_document="index.html"
)
print("Website routing:", website)

# 3. Your own domain. Create the DNS record from the instructions, then verify.
if os.getenv("IBEE_DOMAIN"):
    domain = cdn.create_cdn_custom_domain(
        distribution_id=distribution_id, workspace_id=WORKSPACE_ID, domain=os.environ["IBEE_DOMAIN"]
    )
    print(f"{domain['domain']} is {domain['status']}. Create this DNS record:")
    for line in domain.get("instructions") or []:
        print("  ", line)
    check = cdn.verify_cdn_custom_domain(
        distribution_id=distribution_id, domain=domain["domain"], workspace_id=WORKSPACE_ID
    )
    print("Verification:", check)

# 4. After each deploy, purge the files that changed.
purge = cdn.purge_cdn_cache(
    distribution_id=distribution_id, workspace_id=WORKSPACE_ID, mode="url", paths=["/index.html"]
)
print(f"Purge {'started' if purge['success'] else 'failed'}: {purge.get('purged')}")

# 5. A signed CDN link for one object, valid for one hour.
link = cdn.generate_cdn_url(
    workspace_id=WORKSPACE_ID, bucket_name=BUCKET, object_key="index.html", expires_in=3600
)
print(f"Signed URL: {link['cdn_url']} (expires {link.get('expires_at')})")

if os.getenv("KEEP") != "1":
    cdn.delete_cdn_distribution(distribution_id=distribution_id, workspace_id=WORKSPACE_ID)
    print(f"Deleted {distribution_id}")
