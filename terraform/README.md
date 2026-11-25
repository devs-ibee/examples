# Terraform

Small configurations for the IBEE Terraform provider. Each folder is independent.

| Folder | What it builds | Variables |
|---|---|---|
| [web-app](web-app/) | Two Cloud VMs, a firewall that allows HTTP, and a regional HTTP load balancer in front of them | `site_id`, `plan_id`, `template_id` |
| [private-network](private-network/) | A VPC, a subnet, and an existing VM attached to it | `site_id`, `vm_id` |
| [static-site](static-site/) | A public bucket served through the CDN | `bucket_name`, `storage_region` |
| [private-bucket](private-bucket/) | A private bucket and an S3 key scoped to it | `bucket_name`, `storage_region` |

## Install the provider

Each setup pins `devs-ibee/ibee` to `~> 0.11.0` from the Terraform Registry, so `terraform init` installs it (Terraform 1.11 or later).

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
- The generated S3 secret key and the app login's secret ID are stored in Terraform state; use an encrypted state backend.
- Terraform never reads or writes Secret Manager values. `storage-and-secrets` creates the secret's entry; put the S3 key into it with `bao kv put` as its last comment shows, or in the portal.
- `ibee_secret_manager` turns Secret Manager on for the workspace, permanently. If it is already on, import it first: `terraform import ibee_secret_manager.this "$IBEE_WORKSPACE_ID"`.
- The load balancer's region comes from the `ibee_load_balancer_regions` data source. Its targets are the VMs, by ID; use `{ kind = "ip", address = "10.0.0.10", port = 80 }` for a private address. Each load balancer node is billed per hour.

Review every plan before you apply: these create billable resources.
