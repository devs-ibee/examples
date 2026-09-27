# Storage and secrets

A private bucket for an application, an S3 access key that can only use that bucket, and the key stored in Secret Manager so the application reads it at runtime instead of from its configuration.

## Inputs

| Variable | Description |
|---|---|
| `bucket_name` | Bucket for the application (required) |
| `storage_region` | Object Storage region (default `in-south-2`) |
| `credential_version` | Increase to write the current key into Secret Manager again |

## Run it

```bash
terraform apply -var bucket_name=<bucket>
ibee secrets value "$(terraform output -raw secret_id)"
```

The generated secret access key is stored in Terraform state, so keep state in an encrypted, access-controlled backend. The copy written to Secret Manager uses a write-only argument and is not stored in state a second time.
