# Object Storage

`main.py`, `index.ts` and `cli.sh` create a private bucket and an access key that can only read and write that bucket, list your buckets, then delete both. `s3_quickstart.py` uploads, lists, shares and downloads objects with boto3.

```bash
export IBEE_BUCKET_NAME=my-unique-bucket
export IBEE_STORAGE_REGION=in-south-2    # an Object Storage region, not a compute site

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

The S3 endpoint is `https://<workspace-id>.blob.ibeestorage.com` with path-style addressing. To try boto3, keep the bucket (remove the two delete lines) and save the access key:

```bash
export IBEE_S3_ACCESS_KEY_ID=... IBEE_S3_SECRET_ACCESS_KEY=...
python3 s3_quickstart.py
```

Token scopes: `object-storage.read`, `object-storage.write`, `object-storage.delete`.
