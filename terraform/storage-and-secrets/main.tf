# A private bucket, a bucket-scoped S3 key, and that key stored in Secret Manager.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee" }
  }
}

provider "ibee" {}

variable "bucket_name" {
  type = string
}

variable "storage_region" {
  type        = string
  default     = "in-south-2"
  description = "Object Storage region, not a compute site ID."
}

variable "credential_version" {
  type        = number
  default     = 1
  description = "Increase to write the credential into Secret Manager again."
}

resource "ibee_bucket" "app" {
  name      = var.bucket_name
  region    = var.storage_region
  is_public = false
}

# Least privilege: object read/write on this one bucket.
resource "ibee_s3_credential" "app" {
  name            = "${var.bucket_name}-app"
  permission_type = "object_rw"
  bucket_scope    = "specific"
  allowed_buckets = [ibee_bucket.app.name]
}

resource "ibee_secret_store" "app" {
  name        = "${var.bucket_name}-app"
  description = "Runtime configuration for the ${var.bucket_name} application"
}

resource "ibee_secret" "s3" {
  store_id    = ibee_secret_store.app.id
  secret_name = "object-storage"
  value_wo = jsonencode({
    AWS_ACCESS_KEY_ID     = ibee_s3_credential.app.id
    AWS_SECRET_ACCESS_KEY = ibee_s3_credential.app.secret_access_key
    S3_BUCKET             = ibee_bucket.app.name
  })
  value_wo_version = var.credential_version
}

output "secret_id" {
  value = ibee_secret.s3.id
}

output "access_key_id" {
  value = ibee_s3_credential.app.id
}
