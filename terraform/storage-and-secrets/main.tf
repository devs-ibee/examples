# A private bucket, an S3 key scoped to it, and that key stored in Secret Manager.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee", version = "~> 0.7.0" }
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

resource "ibee_secret_store" "app" {
  name = "${var.bucket_name}-app"
}

# value_wo is write-only: it is never stored in the plan or state. Increase
# value_wo_version to write a new value.
resource "ibee_secret" "s3" {
  store_id    = ibee_secret_store.app.id
  secret_name = "object-storage"
  value_wo = jsonencode({
    AWS_ACCESS_KEY_ID     = ibee_s3_credential.app.id
    AWS_SECRET_ACCESS_KEY = ibee_s3_credential.app.secret_access_key
    S3_BUCKET             = ibee_bucket.app.name
  })
  value_wo_version = 1
}

output "secret_id" {
  value = ibee_secret.s3.id
}
