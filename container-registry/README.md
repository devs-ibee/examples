# Container Registry

Create a registry and a push token, list the registry's repositories, then revoke the token and delete the registry. `push.sh` builds an image, pushes it with a token and pulls it back.

```bash
export IBEE_REGISTRY_NAME=acme-apps-1234       # global and never reused, even after deletion
export IBEE_REGISTRY_SKU=REGISTRY-STORAGE-250GB # a storage plan from the portal

python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI (uses jq)
```

Creating a registry starts billing for its storage plan; the registry service asks Billing and answers (for example 403 `billing_resource_not_eligible`). A token's username and secret are returned once, at creation. A registry must be empty before it is deleted: `empty_container_registry` (`ibee registries empty`) deletes every repository first.

To push an image, create a **Pull and push** token (or use the one above before it is revoked) and run:

```bash
export IBEE_REGISTRY_USERNAME='<username>'   # contains a $, so use single quotes
export IBEE_REGISTRY_TOKEN='<secret>'
bash push.sh
```

On a server or in Kubernetes, log in to `registry.ibee.ai` with a **Pull only** token and use the image `registry.ibee.ai/<registry>/web:<tag>`. Terraform: `ibee_container_registry` and `ibee_container_registry_access_token`.

Token scopes: `container-registry.read`, `container-registry.write`.
