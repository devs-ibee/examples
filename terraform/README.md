# Terraform

Small configurations for the IBEE Terraform provider. Each folder is independent.

| Folder | What it builds | Variables |
|---|---|---|
| [web-app](web-app/) | Two Cloud VMs, a firewall that allows HTTP, and an L7 load balancer | `site_id`, `plan_id`, `template_id` |
| [private-network](private-network/) | A VPC, a subnet, and an existing VM attached to it | `site_id`, `vm_id` |
| [static-site](static-site/) | A public bucket served through the CDN | `bucket_name`, `storage_region` |
| [storage-and-secrets](storage-and-secrets/) | A private bucket, an S3 key for it, and the key in Secret Manager | `bucket_name`, `storage_region` |

## Install the provider

The 0.5.0 provider is not on the Terraform Registry yet. Build it from its branch (Go and Terraform 1.11 or later) and point Terraform at it:

```bash
git clone -b feat/0.5.0-thin https://github.com/devs-ibee/terraform-provider-ibee.git
(cd terraform-provider-ibee && go build -o bin/terraform-provider-ibee .)

cat > "$HOME/.terraformrc-ibee" <<CONFIG
provider_installation {
  dev_overrides { "devs-ibee/ibee" = "$PWD/terraform-provider-ibee/bin" }
  direct {}
}
CONFIG
export TF_CLI_CONFIG_FILE="$HOME/.terraformrc-ibee"
```

With the override, skip `terraform init`.

## Run

```bash
export IBEE_TOKEN="ibee_prod_key_..." IBEE_WORKSPACE_ID="<workspace-id>"

cd web-app
terraform apply -var site_id=... -var plan_id=... -var template_id=...
terraform destroy -var site_id=... -var plan_id=... -var template_id=...
```

- Changing `plan_id` on a VM resizes it in place; the API refuses changes it cannot make.
- `billing_interval` is the plan's billing term to buy. Set it explicitly; changing it replaces the VM.
- Destroying a VM releases its automatic public IP. Set `delete_public_ip_action = "reserve"` to keep it as a Reserved IP.
- Buckets must be empty before they can be destroyed.
- The generated S3 secret key is stored in Terraform state; use an encrypted state backend.

Review every plan before you apply: these create billable resources.
