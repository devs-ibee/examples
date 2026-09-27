# Terraform

Complete stacks built with the IBEE Terraform provider. Each folder is an independent Terraform configuration.

| Stack | What it builds |
|---|---|
| [web-app](web-app/) | Cloud VMs behind an L7 load balancer, with a firewall that allows HTTP, HTTPS, and admin SSH |
| [private-network](private-network/) | A NAT-gateway VPC, a subnet, a VM attachment, and SSH port forwarding |
| [static-site](static-site/) | A public bucket served through the CDN with SPA routing and an optional custom domain |
| [storage-and-secrets](storage-and-secrets/) | A private bucket, a bucket-scoped S3 access key, and that key stored in Secret Manager |
| [gpu-worker](gpu-worker/) | A GPU VM with a block volume for datasets and weekly backups |

## Install the provider

The provider is open source at [devs-ibee/terraform-provider-ibee](https://github.com/devs-ibee/terraform-provider-ibee) and is not yet published to the Terraform Registry. Build it from source (requires Go and Terraform 1.11 or later):

```bash
git clone https://github.com/devs-ibee/terraform-provider-ibee.git
cd terraform-provider-ibee
make build

cat > "$HOME/.terraformrc-ibee" <<CONFIG
provider_installation {
  dev_overrides {
    "devs-ibee/ibee" = "$PWD/bin"
  }
  direct {}
}
CONFIG
export TF_CLI_CONFIG_FILE="$HOME/.terraformrc-ibee"
```

With this override, skip `terraform init` and run `terraform plan` and `terraform apply` directly. Once the provider is on the Terraform Registry, remove the override and run `terraform init` as usual.

## Authenticate

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
# export IBEE_ENV=dev   # to use the development API with an ibee_dev_key_ token
```

The token needs the product scopes each stack uses, plus `billing.read`: the provider checks billing eligibility before every billable create.

## Run a stack

```bash
cd web-app
terraform plan -var site_id=<site-id>
terraform apply -var site_id=<site-id>
terraform destroy -var site_id=<site-id>
```

Get site IDs from `ibee compute sites` or the [getting-started example](../getting-started/). Review every plan before applying: these stacks create billable resources.

## Things to know

- VM settings such as plan, image, SSH keys, and tags are fixed at creation; changing them replaces the VM.
- `delete_public_ip_action` chooses whether a VM's automatic public IP is released (default) or kept as a Reserved IP on destroy.
- Buckets refuse to be destroyed while they contain objects. Empty them first.
- Generated S3 secret keys are stored in Terraform state. Use an encrypted, access-controlled state backend.
- Secret values use write-only arguments (`value_wo`) and are never stored in plan or state. Increase `value_wo_version` to rotate.
