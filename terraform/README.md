# Terraform

Small configurations for the IBEE Terraform provider. Each folder is independent.

| Folder | What it builds | Variables |
|---|---|---|
| [web-app](web-app/) | Two Cloud VMs, a firewall that allows HTTP, and an L7 load balancer | `site_id`, `plan_id`, `template_id` |
| [private-network](private-network/) | A VPC, a subnet, and an existing VM attached to it | `site_id`, `vm_id` |
| [static-site](static-site/) | A public bucket served through the CDN | `bucket_name`, `storage_region` |
| [storage-and-secrets](storage-and-secrets/) | A private bucket, an S3 key for it, and the key in Secret Manager | `bucket_name`, `storage_region` |

## Install the provider

Each setup pins `devs-ibee/ibee` to `~> 0.7.0` from the Terraform Registry, so `terraform init` installs it (Terraform 1.11 or later).

## Run

```bash
export IBEE_TOKEN="ibee_prod_key_..." IBEE_WORKSPACE_ID="<workspace-id>"

cd web-app
terraform init
terraform apply -var site_id=... -var plan_id=... -var template_id=...
terraform destroy -var site_id=... -var plan_id=... -var template_id=...
```

- Changing `plan_id` on a VM resizes it in place; the API refuses changes it cannot make.
- `billing_interval` is `HOURLY` (the default) or `MONTHLY`, a one-month commitment. Changing it replaces the VM.
- `delete_public_ip_action = "release"` gives up a VM's automatic public IP when it is destroyed; the API refuses the destroy without it. Use `"reserve"` to keep the address as a Reserved IP.
- Buckets must be empty before they can be destroyed.
- The generated S3 secret key is stored in Terraform state; use an encrypted state backend.

Review every plan before you apply: these create billable resources.
