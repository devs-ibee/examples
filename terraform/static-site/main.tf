# A public bucket served through the CDN, with SPA routing and an optional domain.

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

variable "enable_spa" {
  type        = bool
  default     = false
  description = "Serve index.html for unknown paths. Enable after index.html is uploaded."
}

variable "domain" {
  type    = string
  default = null
}

resource "ibee_bucket" "site" {
  name      = var.bucket_name
  region    = var.storage_region
  is_public = true
}

resource "ibee_cdn_distribution" "site" {
  name         = "${var.bucket_name}-site"
  origin_type  = "bucket"
  origin_id    = ibee_bucket.site.name
  cache_policy = "static-assets"
  enabled      = true
}

resource "ibee_cdn_website" "site" {
  count = var.enable_spa ? 1 : 0

  distribution_id = ibee_cdn_distribution.site.id
  index_document  = "index.html"
}

resource "ibee_cdn_domain" "site" {
  count = var.domain == null ? 0 : 1

  distribution_id = ibee_cdn_distribution.site.id
  domain          = var.domain
}

output "cdn_url" {
  value = ibee_cdn_distribution.site.default_url
}

output "domain_cname" {
  value = var.domain == null ? null : {
    name   = ibee_cdn_domain.site[0].cname_name
    target = ibee_cdn_domain.site[0].cname_target
  }
}
