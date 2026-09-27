<h3>IBEE examples</h3>

Working examples for every [IBEE](https://ibee.ai) cloud product, written against the public API with the official Python SDK, TypeScript SDK, `ibee` CLI, plain HTTP, and the Terraform provider.

## Examples

| Example | What it shows | Python | TypeScript | CLI | HTTP | Terraform |
|---|---|:-:|:-:|:-:|:-:|:-:|
| [Getting started](getting-started/) | Check credentials; list sites, plans, images; check billing | ✓ | ✓ | ✓ | ✓ | |
| [Cloud VMs](cloud-vms/) | Create, wait, stop, start, and delete a VM | ✓ | ✓ | ✓¹ | ✓ | [web-app](terraform/web-app/) |
| [GPU VMs](gpu-vms/) | Create a GPU VM from a priced GPU plan | ✓ | ✓ | ✓¹ | ✓ | [gpu-worker](terraform/gpu-worker/) |
| [VM operations](vm-operations/) | Metrics, events, resize, SSH access, browser console | ✓ | ✓ | ✓ | ✓ | |
| [Snapshots and backups](snapshots-and-backups/) | Scheduled and on-demand backups, snapshots, recovery points | ✓ | ✓ | ✓ | ✓ | [gpu-worker](terraform/gpu-worker/) |
| [Block Storage](block-storage/) | Create, attach, grow, detach, and delete a volume | ✓ | ✓ | ✓ | ✓ | [gpu-worker](terraform/gpu-worker/) |
| [Object Storage](object-storage/) | Buckets, scoped S3 keys, boto3, and an s3fs mount | ✓ | ✓ | ✓ | ✓ | [storage-and-secrets](terraform/storage-and-secrets/) |
| [CDN](cdn/) | Serve a bucket, SPA routing, custom domain, purge, signed URLs | ✓ | ✓ | ✓ | ✓ | [static-site](terraform/static-site/) |
| [VPC and NAT gateway](vpc/) | Private network, NAT egress, port forwarding | ✓ | ✓ | ✓ | ✓ | [private-network](terraform/private-network/) |
| [Virtual IPs](virtual-ips/) | A private address you choose, announced by MetalLB | ² | ² | ² | ✓ | |
| [Reserved IPs](reserved-ips/) | Reserve, attach, move, and release a public IP | ✓ | ✓ | ✓ | ✓ | |
| [Firewalls](firewalls/) | A web-server firewall group attached to a VM | ✓ | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [Load Balancers](load-balancers/) | L7 HTTP with path routing, and L4 TCP | ✓ | ✓ | ✓ | ✓ | [web-app](terraform/web-app/) |
| [Secret Manager](secret-manager/) | Stores, versioned secrets, rollback, AppRole identities | ✓ | ✓ | ✓ | ✓ | [storage-and-secrets](terraform/storage-and-secrets/) |
| [Container Registry](container-registry/) | Push and pull images, GitHub Actions, Kubernetes | ³ | ³ | ³ | Docker | |
| [Terraform](terraform/) | Five complete stacks built with the IBEE provider | | | | | ✓ |

¹ CLI 0.3.0 cannot create or delete Cloud or GPU VMs, so these CLI scripts cover day-2 operations. The Python, TypeScript, and HTTP examples cover the full lifecycle.

² Virtual IPs are available through the public API but are not in the SDKs or CLI yet, so the example uses HTTP calls.

³ Registries and access tokens are created in the portal; images are pushed and pulled with standard Docker and OCI tools.

Bare Metal Servers, SSH Keys, ISOs, and Email Service are managed in the [portal](https://portal.ibee.ai) and have no public API yet, so they have no examples here. DNS and SSL Certificates are not available yet.

## Set up

1. Create an API token under **API Tokens** in the [portal](https://portal.ibee.ai) with the scopes each example lists, and note your workspace ID.
2. Export them:

   ```bash
   export IBEE_TOKEN="ibee_prod_key_..."
   export IBEE_WORKSPACE_ID="<workspace-id>"
   ```

   Set `IBEE_ENV=dev` with an `ibee_dev_key_...` token to use the development API.

3. Install the tools for the interface you want:

   ```bash
   pip install -r requirements.txt   # Python SDK, CLI, and boto3
   npm install                       # TypeScript SDK and tsx
   ```

Run an example from its folder, for example `python3 cloud-vms/main.py` or `npx tsx cloud-vms/index.ts`. Every README lists the inputs and scopes it needs.

Most examples create billable resources and clean them up at the end. Set `KEEP=1` to keep what an example creates.

## Docs

These examples cover the most common workflows. For everything else, see the documentation.

- [Product docs](https://ibee.ai/docs)
- [API reference](https://ibee.ai/docs/api-reference)
- [Python and TypeScript SDKs](https://ibee.ai/docs/api-reference/sdk-overview)
- [CLI](https://ibee.ai/docs/api-reference/cli)
- [Terraform provider](https://github.com/devs-ibee/terraform-provider-ibee)

## Feedback and contributions

- [Open an issue](https://github.com/devs-ibee/examples/issues) for questions, bug reports, or requests for new examples.
- Pull requests with fixes and new examples are welcome.
