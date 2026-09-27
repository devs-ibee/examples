# A NAT-gateway VPC with a subnet, one attached VM, and SSH port forwarding.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee" }
  }
}

provider "ibee" {}

variable "vm_id" {
  type        = string
  description = "Existing VM to attach. It must be at the VPC's site."
}

variable "site_id" {
  type        = string
  default     = null
  description = "Networking site. Defaults to the first available site."
}

variable "cidr" {
  type    = string
  default = "10.44.0.0/22"
}

data "ibee_network_sites" "all" {}

locals {
  site_id = coalesce(var.site_id, try([for s in data.ibee_network_sites.all.sites : s.site_id if s.available][0], null))
}

# The managed NAT gateway is created with the VPC and deleted with it.
resource "ibee_vpc" "main" {
  name                  = "private-network"
  site_id               = local.site_id
  cidr                  = var.cidr
  create_default_subnet = false
  connectivity_type     = "nat_gateway"
}

resource "ibee_vpc_subnet" "apps" {
  vpc_id = ibee_vpc.main.id
  name   = "applications"
  cidr   = cidrsubnet(var.cidr, 2, 0)
}

resource "ibee_vpc_node_attachment" "vm" {
  vpc_id       = ibee_vpc.main.id
  subnet_id    = ibee_vpc_subnet.apps.id
  vm_id        = var.vm_id
  connectivity = "nat"
}

resource "ibee_nat_port_forwarding_rule" "ssh" {
  vpc_id         = ibee_vpc.main.id
  nat_gateway_id = ibee_vpc.main.default_nat_gateway_id
  name           = "ssh"
  protocol       = "tcp"
  external_port  = 2222
  internal_ip    = ibee_vpc_node_attachment.vm.private_ip
  internal_port  = 22
}

output "private_ip" {
  value = ibee_vpc_node_attachment.vm.private_ip
}

output "nat_gateway_id" {
  value = ibee_vpc.main.default_nat_gateway_id
}
