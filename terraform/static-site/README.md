# Static site on the CDN

A public bucket for your built site, a CDN distribution in front of it, single-page-app routing, and an optional custom domain.

## Inputs

| Variable | Description |
|---|---|
| `bucket_name` | Bucket for the site files (required) |
| `storage_region` | Object Storage region (default `in-south-2`) |
| `enable_spa` | Serve `index.html` for unknown paths; enable after uploading `index.html` |
| `domain` | Your own domain, for example `www.example.com` (optional) |

## Run it

```bash
terraform apply -var bucket_name=<bucket>

# Upload the site, then turn on SPA routing.
aws s3 sync ./dist "s3://<bucket>" --endpoint-url "https://$IBEE_WORKSPACE_ID.blob.ibeestorage.com"
terraform apply -var bucket_name=<bucket> -var enable_spa=true -var domain=www.example.com
terraform output domain_cname   # create this CNAME record at your DNS provider
```

The certificate for a custom domain is issued after the CNAME record resolves, which can take several minutes. Terraform does not upload files; use any S3 tool.
