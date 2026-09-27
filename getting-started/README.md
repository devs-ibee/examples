# Getting started

Check that your API token and workspace work, then discover the IDs every other example needs: compute sites, priced VM plans, OS images, networking sites, and whether billing allows a new resource.

## What it does

1. Lists the compute sites where VMs can run.
2. Lists priced cloud VM plans, cheapest first.
3. Lists cloud OS images.
4. Lists networking sites and whether each one is available.
5. Asks billing whether the workspace may create an Object Storage bucket.

Nothing is created, so this example is free to run.

## Requirements

- An API token from **API Tokens** in the portal with `vm.read`, `network.read`, and `billing.read`.
- The ID of the workspace to use.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"

python3 main.py            # Python SDK
npx tsx index.ts           # TypeScript SDK
bash cli.sh                # ibee CLI
bash api.sh                # curl and jq
```

Set `IBEE_ENV=dev` with an `ibee_dev_key_...` token to use the development API instead of production.
