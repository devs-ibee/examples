"""Upload, list, share, download, and delete an object with boto3 (pip install boto3)."""

import os

import boto3
from botocore.config import Config

bucket = os.environ["IBEE_BUCKET_NAME"]
s3 = boto3.client(
    "s3",
    endpoint_url=f"https://{os.environ['IBEE_WORKSPACE_ID']}.blob.ibeestorage.com",
    aws_access_key_id=os.environ["IBEE_S3_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["IBEE_S3_SECRET_ACCESS_KEY"],
    region_name="us-east-1",  # boto3 needs a value; IBEE ignores it
    config=Config(s3={"addressing_style": "path"}),
)

s3.put_object(Bucket=bucket, Key="hello.txt", Body=b"Hello from IBEE Object Storage\n", ContentType="text/plain")

for item in s3.list_objects_v2(Bucket=bucket).get("Contents", []):
    print(f"{item['Key']}  {item['Size']} bytes")

# Share the object for one hour without making the bucket public.
print(s3.generate_presigned_url("get_object", Params={"Bucket": bucket, "Key": "hello.txt"}, ExpiresIn=3600))

print(s3.get_object(Bucket=bucket, Key="hello.txt")["Body"].read().decode())
s3.delete_object(Bucket=bucket, Key="hello.txt")
