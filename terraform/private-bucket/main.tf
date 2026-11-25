# A private bucket and an S3 key scoped to it.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee", version = "~> 0.11.0" }
  }
}

provider "ibee" {} # reads IBEE_TOKEN and IBEE_WORKSPACE_ID

variable "bucket_name" {
  type = string
}

variable "storage_region" {
  type        = string
  description = "Object Storage region, for example in-south-2 (not a compute site)."
}

variable "secret_namespace" {
  type        = string
  description = "Secret Manager namespace: 3 to 32 lowercase letters, digits or hyphens, unique across IBEE. It can't change later."
}

resource "ibee_bucket" "app" {
  name   = var.bucket_name
  region = var.storage_region
}

resource "ibee_s3_credential" "app" {
  name            = "${var.bucket_name}-app"
  permission_type = "object_rw"
  bucket_scope    = "specific"
  allowed_buckets = [ibee_bucket.app.name]
}

output "access_key_id" {
  value = ibee_s3_credential.app.id
}

# Keep the secret key out of logs: read it with `terraform output -raw secret_access_key`
# and store it in your application's secret store.
output "secret_access_key" {
  value     = ibee_s3_credential.app.secret_access_key
  sensitive = true
}

output "s3_access_key_id" {
  value = ibee_s3_credential.app.id
}

output "s3_secret_access_key" {
  value     = ibee_s3_credential.app.secret_access_key
  sensitive = true
}

output "vault_endpoint" {
  value = ibee_secret_manager.this.endpoint
}

output "secret_path" {
  value = ibee_secret_manager_secret.s3.path
}

output "app_role_id" {
  value = ibee_secret_manager_app_credential.app.role_id
}

output "app_secret_id" {
  value     = ibee_secret_manager_app_credential.app.secret_id
  sensitive = true
}

# After apply, put the S3 key into the secret with bao, signed in with a
# read_write login (or paste it in the portal):
#
#   export BAO_ADDR="$(terraform output -raw vault_endpoint)" BAO_NAMESPACE=<secret_namespace>
#   terraform output -raw s3_secret_access_key |
#     bao kv put -mount=secret "$(terraform output -raw secret_path)" \
#       AWS_ACCESS_KEY_ID="$(terraform output -raw s3_access_key_id)" AWS_SECRET_ACCESS_KEY=-
