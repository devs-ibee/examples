# A public bucket served through the CDN.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee", version = "~> 0.5.0" }
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

resource "ibee_bucket" "site" {
  name      = var.bucket_name
  region    = var.storage_region
  is_public = true
}

resource "ibee_cdn_distribution" "site" {
  name        = "${var.bucket_name}-site"
  origin_type = "bucket"
  origin_id   = ibee_bucket.site.name
}

output "cdn_url" {
  value = ibee_cdn_distribution.site.default_url
}
