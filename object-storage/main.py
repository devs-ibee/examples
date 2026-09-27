"""Object Storage: a private bucket plus an access key scoped to that bucket.

Requires: pip install ibee
Environment:
  IBEE_TOKEN           API token (object-storage.read/write/delete)
  IBEE_WORKSPACE_ID    workspace ID
  IBEE_STORAGE_REGION  Object Storage region (default in-south-2)
  IBEE_BUCKET_NAME     bucket name (optional)
  IBEE_ENV             "dev" to use the development API (optional)
  KEEP                 set to 1 to keep the bucket and access key
"""

import os
import uuid

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
storage = client.object_storage

# 1. A private bucket.
bucket = storage.create_bucket(
    workspace_id=WORKSPACE_ID,
    name=os.getenv("IBEE_BUCKET_NAME") or f"example-{uuid.uuid4().hex[:8]}",
    region=os.getenv("IBEE_STORAGE_REGION", "in-south-2"),
    is_public=False,
    tags=["example"],
)
print(f"Bucket {bucket.name} in {bucket.region} ({'public' if bucket.is_public else 'private'})")

# 2. An access key that can only read and write objects in this bucket.
key = storage.create_s3credential(
    workspace_id=WORKSPACE_ID,
    name=f"{bucket.name}-app",
    permission_type="object_rw",
    bucket_scope="specific",
    allowed_buckets=[bucket.name],
)
print(f"Access key ID:     {key.access_key_id}")
print(f"Secret access key: {key.secret_access_key}   (shown only once; store it now)")
print(f"S3 endpoint:       https://{WORKSPACE_ID}.blob.ibeestorage.com")

for existing in storage.list_buckets(workspace_id=WORKSPACE_ID).buckets or []:
    print(f"  bucket {existing.name}: {existing.object_count} objects, {existing.total_size} bytes")

# 3. Clean up. A bucket must be empty before it can be deleted.
if os.getenv("KEEP") != "1":
    storage.revoke_s3credential(access_key_id=key.access_key_id, workspace_id=WORKSPACE_ID)
    storage.delete_bucket(bucket_name=bucket.name, workspace_id=WORKSPACE_ID)
    print("Revoked the access key and deleted the bucket")
