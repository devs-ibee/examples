# Two Cloud VMs behind an L7 load balancer, with a firewall that allows HTTP.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee", version = "~> 0.7.0" }
  }
}

provider "ibee" {} # reads IBEE_TOKEN and IBEE_WORKSPACE_ID

variable "site_id" {
  type = string
}

variable "plan_id" {
  type        = string
  description = "VM plan. Change it and apply again to resize the VMs in place."
}

variable "template_id" {
  type = string
}

variable "os_distro" {
  type        = string
  default     = "ubuntu"
  description = "The image's os_distro."
}

variable "ssh_key_ids" {
  type    = set(string)
  default = []
}

resource "ibee_cloud_vm" "web" {
  count = 2

  name             = "web-${count.index + 1}"
  site_id          = var.site_id
  plan_id          = var.plan_id
  template_id      = var.template_id
  os_distro        = var.os_distro
  billing_interval = "HOURLY"
  ssh_key_ids      = var.ssh_key_ids

  # The API refuses to delete a VM with an automatically assigned public IP
  # unless the caller chooses; the provider has no default. "reserve" keeps it.
  delete_public_ip_action = "release"
}

resource "ibee_firewall_group" "web" {
  name = "web"
}

resource "ibee_firewall_rule" "http" {
  firewall_group_id = ibee_firewall_group.web.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = 80
  port_end          = 80
  remote_targets    = ["0.0.0.0/0"]
  action            = "allow"
}

resource "ibee_firewall_attachment" "web" {
  count = 2

  firewall_group_id = ibee_firewall_group.web.id
  vm_id             = ibee_cloud_vm.web[count.index].id
  depends_on        = [ibee_firewall_rule.http]
}

resource "ibee_load_balancer_l7" "web" {
  name     = "web"
  protocol = "http"
  backends = [for vm in ibee_cloud_vm.web : { type = "ip", target = vm.public_ip, port = 80 }]
}

output "url" {
  value = ibee_load_balancer_l7.web.endpoint_url
}

output "vm_public_ips" {
  value = ibee_cloud_vm.web[*].public_ip
}
