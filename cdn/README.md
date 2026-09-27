# CDN

Serve a single-page app or static assets from an Object Storage bucket through the IBEE CDN, add your own domain, purge the cache after a deploy, and issue expiring download links.

## What it does

1. Creates a CDN distribution in front of a bucket (`IBEE_BUCKET_NAME`) with the `static-assets` cache policy.
2. Turns on single-page-app routing, so unknown paths return `index.html`.
3. With `IBEE_DOMAIN` set, adds the domain and prints the DNS record to create, then asks the CDN to verify it.
4. Purges `/index.html` from the cache, as you would after each deploy.
5. Generates a one-hour signed CDN URL for a single object.
6. Deletes the distribution. Set `KEEP=1` to keep it.

## Requirements

- An API token with `cdn.read` and `cdn.write`.
- A public bucket that already contains your site's `index.html`. Upload with the AWS CLI:

```bash
aws s3 sync ./dist "s3://$IBEE_BUCKET_NAME" --endpoint-url "https://$IBEE_WORKSPACE_ID.blob.ibeestorage.com"
```

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_BUCKET_NAME="<public-bucket>"
export IBEE_DOMAIN="app.example.com"   # optional

python3 main.py
bash cli.sh
```

## Cache policies and purging

| Cache policy | Use for |
|---|---|
| `static-assets` | Versioned JS, CSS, fonts, and images |
| `media` | Large video and audio files |
| `short` | Content that changes often |
| `no-cache` | Content that must always come from the bucket |

Purge by URL (`mode: "url"` with `paths`) after each deploy. Purging by prefix is accepted by the API but does not currently clear bucket-origin distributions, so list the exact paths to refresh.

Custom domains become `active` after you create the CNAME record the API returns and the TLS certificate is issued. This can take several minutes.
