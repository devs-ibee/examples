# A GPU VM with a dataset volume and weekly backups.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee" }
  }
}

provider "ibee" {
  operation_timeout = "45m"
}

variable "site_id" {
  type = string
}

variable "plan_id" {
  type        = string
  default     = null
  description = "GPU plan. Defaults to the cheapest priced GPU plan at the site."
}

variable "block_sku_code" {
  type        = string
  description = "Active Block Storage SKU from the portal."
}

variable "data_volume_gb" {
  type    = number
  default = 200
}

variable "ssh_key_ids" {
  type    = set(string)
  default = []
}

variable "confirm_volume_unmounted" {
  type        = bool
  default     = false
  description = "Set to true only after unmounting the volume inside the VM, before destroy."
}

data "ibee_compute_plans" "gpu" {
  vm_type          = "gpu"
  site_id          = var.site_id
  billing_interval = "HOURLY"
}

data "ibee_images" "gpu" {
  vm_type = "gpu"
}

locals {
  priced_plans = [for p in data.ibee_compute_plans.gpu.plans : p if p.selectable && p.pricing_status == "priced" && p.gpu_count > 0]
  cheapest     = try(min([for p in local.priced_plans : p.hourly_price_minor]...), null)
  plan_id      = coalesce(var.plan_id, try([for p in local.priced_plans : p.plan_id if p.hourly_price_minor == local.cheapest][0], null))
  image        = try([for i in data.ibee_images.gpu.images : i if i.os_distro == "ubuntu"][0], data.ibee_images.gpu.images[0])
}

resource "ibee_gpu_vm" "worker" {
  name                    = "gpu-worker"
  site_id                 = var.site_id
  plan_id                 = local.plan_id
  template_id             = local.image.template_id
  os_distro               = local.image.os_distro
  billing_interval        = "HOURLY"
  ssh_key_ids             = var.ssh_key_ids
  tags                    = ["gpu", "worker"]
  delete_public_ip_action = "release"
}

resource "ibee_block_volume" "datasets" {
  name         = "gpu-worker-datasets"
  site_id      = var.site_id
  sku_code     = var.block_sku_code
  size_gb      = var.data_volume_gb
  volume_class = "performance"
  vm_type      = "gpu"
}

resource "ibee_gpu_vm_volume_attachment" "datasets" {
  vm_id             = ibee_gpu_vm.worker.id
  volume_id         = ibee_block_volume.datasets.id
  confirm_unmounted = var.confirm_volume_unmounted
}

# Weekly on Sunday (Monday=0 through Sunday=6) at 02:00 UTC, kept for 28 days.
resource "ibee_gpu_vm_backup_policy" "worker" {
  vm_id          = ibee_gpu_vm.worker.id
  frequency      = "weekly"
  day_of_week    = 6
  hour           = 2
  timezone       = "UTC"
  retention_days = 28
}

output "public_ip" {
  value = ibee_gpu_vm.worker.public_ip
}

output "gpu" {
  value = "${ibee_gpu_vm.worker.gpu_count} x ${ibee_gpu_vm.worker.gpu_model}"
}

output "mount_instructions" {
  value = ibee_gpu_vm_volume_attachment.datasets.mount_instructions
}
