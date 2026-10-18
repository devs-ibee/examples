# Getting started

Check that your token works and find the IDs the other examples need: sites, plans and images. Nothing is created.

```bash
python3 main.py      # Python SDK
npx tsx index.ts     # TypeScript SDK
bash cli.sh          # ibee CLI
bash api.sh          # curl and jq
```

Copy a `site_id`, a `plan_id` from that site and a `template_id` into `IBEE_SITE_ID`, `IBEE_PLAN_ID` and `IBEE_TEMPLATE_ID`. For GPU plans and images, use `vm_type="gpu"` (`--vm-type gpu`).

Token scope: `vm.read`.
