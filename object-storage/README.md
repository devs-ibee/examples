# Object Storage

Create a bucket and a least-privilege S3 access key, then use any S3-compatible tool with it: the AWS CLI, boto3, rclone, or s3fs.

## What it does

- `main.py`, `index.ts`, `cli.sh`, and `api.sh` create a private bucket and an access key that can read and write objects in that bucket only, then revoke the key and delete the bucket. Set `KEEP=1` to keep both.
- `s3_quickstart.py` uploads, lists, shares with a presigned URL, and downloads objects with boto3.
- `mount-filesystem.sh` mounts a bucket as a local directory with s3fs.

## Requirements

- An API token with `object-storage.read`, `object-storage.write`, and `object-storage.delete`.
- An Object Storage region (`IBEE_STORAGE_REGION`, default `in-south-2`). This is a storage region, not a compute site ID.
- A bucket name that is unique within your workspace (`IBEE_BUCKET_NAME`, optional).

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
bash api.sh          # curl and jq
```

Then use the printed access key with S3 tools:

```bash
export IBEE_S3_ACCESS_KEY_ID="<access-key-id>"
export IBEE_S3_SECRET_ACCESS_KEY="<secret-access-key>"
export IBEE_BUCKET_NAME="<bucket>"

python3 s3_quickstart.py
sudo -E bash mount-filesystem.sh "$IBEE_BUCKET_NAME" /mnt/bucket
```

## S3 endpoint

Every S3 tool uses your workspace's endpoint with path-style addressing:

```text
https://<workspace-id>.blob.ibeestorage.com
```

```bash
aws s3 ls "s3://$IBEE_BUCKET_NAME" --endpoint-url "https://$IBEE_WORKSPACE_ID.blob.ibeestorage.com"
```

## Access key permissions

| `permission_type` | Access |
|---|---|
| `object_ro` | Read objects in the allowed buckets |
| `object_rw` | Read and write objects in the allowed buckets |
| `admin_ro` | Read all buckets and their settings |
| `admin_rw` | Full access to every bucket |

Use `object_ro` or `object_rw` with `bucket_scope` set to `specific` for applications. The secret access key is returned only once, when the key is created.
