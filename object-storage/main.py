"""Create a private bucket and an S3 access key for it, then delete both."""

import os

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
storage = client.object_storage

bucket = storage.create_bucket(name=os.environ["IBEE_BUCKET_NAME"], region=os.environ["IBEE_STORAGE_REGION"])
print(f"Bucket {bucket.name} in {bucket.region}")

# An access key that can read and write objects in this bucket only.
key = storage.create_s3credential(
    name=f"{bucket.name}-app",
    permission_type="object_rw",
    bucket_scope="specific",
    allowed_buckets=[bucket.name],
)
print(f"Access key {key.access_key_id} (the secret key is shown only once)")

for item in storage.list_buckets().buckets or []:
    print(f"  {item.name}  {item.object_count} objects")

storage.revoke_s3credential(key.access_key_id)
storage.delete_bucket(bucket.name)  # a bucket must be empty to delete it
