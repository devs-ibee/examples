# CDN

Serve a public bucket through the CDN, turn on single-page-app routing, purge a path, then delete the distribution.

```bash
export IBEE_BUCKET_NAME=...   # a public bucket that holds index.html

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
```

Add your own domain with `create_cdn_custom_domain` and `verify_cdn_custom_domain` (`ibee cdn domains create`, `ibee cdn domains verify`), and sign links to private objects with `generate_cdn_url` (`ibee cdn generate-url`).

Token scopes: `cdn.read`, `cdn.write`.
