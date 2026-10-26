# Docs files for AI tools

Storage for two machine-readable copies of the IBEE documentation. They are
served to readers under ibee.ai addresses, not from here:

| File | Served at |
|---|---|
| `llms-full.txt` — the full text of every docs page in one file | https://ibee.ai/docs/llms-full.txt |
| `llms.txt` — index of every docs page, one line each | https://ibee.ai/docs/llms.txt (Fern's own index) |

`../contract/ibee-cloud.yaml`, the complete public API specification, is served at
https://ibee.ai/docs/openapi/ibee-cloud.yaml.

The files are generated from the published site by `scripts/build_agent_files.py`
in the docs repository and refreshed after each production docs deploy.
