"""Upload, list, share, and download objects with boto3.

Requires: pip install boto3
Environment:
  IBEE_WORKSPACE_ID          workspace ID (it is part of the S3 endpoint)
  IBEE_S3_ACCESS_KEY_ID      access key from main.py or the portal
  IBEE_S3_SECRET_ACCESS_KEY  its secret access key
  IBEE_BUCKET_NAME           bucket the key can write to
"""

import os
import pathlib
import tempfile

import boto3
from botocore.config import Config

bucket = os.environ["IBEE_BUCKET_NAME"]
s3 = boto3.client(
    "s3",
    endpoint_url=f"https://{os.environ['IBEE_WORKSPACE_ID']}.blob.ibeestorage.com",
    aws_access_key_id=os.environ["IBEE_S3_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["IBEE_S3_SECRET_ACCESS_KEY"],
    region_name="us-east-1",  # required by boto3; IBEE ignores it
    config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
)

# Upload a file.
with tempfile.TemporaryDirectory() as tmp:
    source = pathlib.Path(tmp, "hello.txt")
    source.write_text("Hello from IBEE Object Storage\n")
    s3.upload_file(str(source), bucket, "examples/hello.txt", ExtraArgs={"ContentType": "text/plain"})

    # List objects under a prefix.
    for item in s3.list_objects_v2(Bucket=bucket, Prefix="examples/").get("Contents", []):
        print(f"{item['Key']}  {item['Size']} bytes")

    # Share an object for one hour without making the bucket public.
    url = s3.generate_presigned_url("get_object", Params={"Bucket": bucket, "Key": "examples/hello.txt"}, ExpiresIn=3600)
    print(f"Presigned URL (valid for 1 hour): {url}")

    # Download it back.
    target = pathlib.Path(tmp, "downloaded.txt")
    s3.download_file(bucket, "examples/hello.txt", str(target))
    print("Downloaded:", target.read_text().strip())

    # Delete the object.
    s3.delete_object(Bucket=bucket, Key="examples/hello.txt")
