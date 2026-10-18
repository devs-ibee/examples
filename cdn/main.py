"""Put the CDN in front of a public bucket, purge a path, and delete the distribution."""

import os

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV

distribution = client.cdn.create_cdn_distribution(
    name="example-site",
    origin_type="bucket",
    origin_id=os.environ["IBEE_BUCKET_NAME"],
)
print(f"Distribution {distribution.id} is {distribution.status}: {distribution.default_url}")

# Serve index.html for unknown paths (single-page apps).
client.cdn.update_cdn_website_config(distribution.id, index_document="index.html")

# After a deploy, purge the files that changed.
purge = client.cdn.purge_cdn_cache(distribution.id, mode="url", paths=["/index.html"])
print(f"Purge succeeded: {purge.success}")

client.cdn.delete_cdn_distribution(distribution.id)
