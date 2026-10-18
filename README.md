<h3>IBEE examples</h3>

Short, runnable examples for [IBEE](https://ibee.ai) cloud products with the Python SDK, the TypeScript SDK, the `ibee` CLI and the Terraform provider. Each example does one task, usually: create a resource, read it, and delete it.

| Product | Python | TypeScript | CLI | Terraform |
|---|:-:|:-:|:-:|:-:|
| [Getting started](getting-started/) (also `curl`) | ✓ | ✓ | ✓ | |
| [Cloud VMs](cloud-vms/) | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [GPU VMs](gpu-vms/) | ✓ | ✓ | ✓ | |
| [VM operations](vm-operations/) | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [Snapshots and backups](snapshots-and-backups/) | ✓ | ✓ | ✓ | |
| [Block Storage](block-storage/) | ✓ | ✓ | ✓ | |
| [Object Storage](object-storage/) (also boto3) | ✓ | ✓ | ✓ | [storage-and-secrets](terraform/storage-and-secrets/) |
| [CDN](cdn/) | ✓ | ✓ | ✓ | [static-site](terraform/static-site/) |
| [VPC](vpc/) | ✓ | ✓ | ✓ | [private-network](terraform/private-network/) |
| [Reserved IPs](reserved-ips/) | ✓ | ✓ | ✓ | |
| [Firewalls](firewalls/) | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [Load Balancers](load-balancers/) | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [Secret Manager](secret-manager/) | ✓ | ✓ | ✓ | [storage-and-secrets](terraform/storage-and-secrets/) |
| [Container Registry](container-registry/) | Docker | | | |

Portal only, with no public API yet: Virtual IPs, Bare Metal, SSH keys, ISOs, Email, and creating Container Registries and their tokens.

## Install

```bash
pip install ibee ibee-cli boto3    # or: pip install -r requirements.txt
npm install                        # ibee-sdk, tsx and TypeScript from package.json
```

For Terraform, see [terraform/](terraform/).

## Configure

Create an API token under **API Tokens** in the [portal](https://portal.ibee.ai) with the scopes each example lists.

| Variable | Use |
|---|---|
| `IBEE_TOKEN` | API token (`ibee_prod_key_...`) |
| `IBEE_WORKSPACE_ID` | Workspace to work in |
| `IBEE_ENV` | `dev` to use the development API with an `ibee_dev_key_...` token |

Each example's README lists the other inputs it reads, such as `IBEE_SITE_ID` or `IBEE_VM_ID`. Run the [getting-started](getting-started/) example first to find site, plan and image IDs.

```bash
python3 cloud-vms/main.py
npx tsx cloud-vms/index.ts
bash cloud-vms/cli.sh
```

Most examples create billable resources for a few minutes and delete them at the end.

## Docs

- [Product docs](https://ibee.ai/docs) and [API reference](https://ibee.ai/docs/api-reference)
- [Python SDK](https://github.com/devs-ibee/ibee-python), [TypeScript SDK](https://github.com/devs-ibee/ibee-typescript), [CLI](https://github.com/devs-ibee/ibee-cli), [Terraform provider](https://github.com/devs-ibee/terraform-provider-ibee)

[Open an issue](https://github.com/devs-ibee/examples/issues) for questions or requests. Pull requests are welcome.
