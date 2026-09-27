# Cloud VMs behind an L7 load balancer, protected by a firewall group.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee" }
  }
}

# Reads IBEE_TOKEN and IBEE_WORKSPACE_ID from the environment.
provider "ibee" {}

variable "site_id" {
  type        = string
  description = "Compute site for the VMs, from `ibee compute sites`."
}

variable "vm_count" {
  type    = number
  default = 2
}

variable "plan_id" {
  type        = string
  default     = null
  description = "VM plan. Defaults to the cheapest priced plan at the site."
}

variable "ssh_key_ids" {
  type    = set(string)
  default = []
}

variable "admin_cidr" {
  type        = string
  default     = null
  description = "Network allowed to use SSH, for example 198.51.100.7/32. Leave unset to block SSH."
}

data "ibee_compute_plans" "cloud" {
  vm_type          = "cloud"
  site_id          = var.site_id
  billing_interval = "HOURLY"
}

data "ibee_images" "cloud" {
  vm_type = "cloud"
}

locals {
  priced_plans = [for p in data.ibee_compute_plans.cloud.plans : p if p.selectable && p.pricing_status == "priced"]
  cheapest     = try(min([for p in local.priced_plans : p.hourly_price_minor]...), null)
  plan_id      = coalesce(var.plan_id, try([for p in local.priced_plans : p.plan_id if p.hourly_price_minor == local.cheapest][0], null))
  image        = try([for i in data.ibee_images.cloud.images : i if i.os_distro == "ubuntu"][0], data.ibee_images.cloud.images[0])
}

resource "ibee_cloud_vm" "web" {
  count = var.vm_count

  name             = "web-${count.index + 1}"
  site_id          = var.site_id
  plan_id          = local.plan_id
  template_id      = local.image.template_id
  os_distro        = local.image.os_distro
  billing_interval = "HOURLY"
  ssh_key_ids      = var.ssh_key_ids
  tags             = ["web"]

  # Release the automatic public IP when the VM is destroyed.
  delete_public_ip_action = "release"
}

resource "ibee_firewall_group" "web" {
  name        = "web"
  description = "HTTP and HTTPS from anywhere, SSH from the admin network"
}

resource "ibee_firewall_rule" "http" {
  for_each = toset(["80", "443"])

  firewall_group_id = ibee_firewall_group.web.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = tonumber(each.value)
  port_end          = tonumber(each.value)
  remote_targets    = ["0.0.0.0/0"]
  action            = "allow"
}

resource "ibee_firewall_rule" "ssh" {
  count = var.admin_cidr == null ? 0 : 1

  firewall_group_id = ibee_firewall_group.web.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = 22
  port_end          = 22
  remote_targets    = [var.admin_cidr]
  action            = "allow"
}

# Attach only after the rules exist, so the VMs never run with a partial rule set.
resource "ibee_firewall_attachment" "web" {
  count = var.vm_count

  firewall_group_id = ibee_firewall_group.web.id
  vm_id             = ibee_cloud_vm.web[count.index].id
  depends_on        = [ibee_firewall_rule.http, ibee_firewall_rule.ssh]
}

resource "ibee_load_balancer_l7" "web" {
  name     = "web"
  protocol = "http"
  backends = [for vm in ibee_cloud_vm.web : {
    type   = "ip"
    target = vm.public_ip
    port   = 80
  }]
}

output "load_balancer_url" {
  value = ibee_load_balancer_l7.web.endpoint_url
}

output "vm_public_ips" {
  value = ibee_cloud_vm.web[*].public_ip
}
