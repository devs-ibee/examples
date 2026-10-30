# A VPC with one subnet and an existing VM attached to it.

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    ibee = { source = "devs-ibee/ibee", version = "~> 0.7.0" }
  }
}

provider "ibee" {} # reads IBEE_TOKEN and IBEE_WORKSPACE_ID

variable "site_id" {
  type        = string
  description = "Networking site, from `ibee vpcs sites`."
}

variable "vm_id" {
  type        = string
  description = "An existing VM at that site."
}

# Without a cidr, the API picks free address ranges for the VPC and the subnet.
resource "ibee_vpc" "main" {
  name                  = "private-network"
  site_id               = var.site_id
  create_default_subnet = false
}

resource "ibee_vpc_subnet" "apps" {
  vpc_id = ibee_vpc.main.id
  name   = "apps"
}

resource "ibee_vpc_node_attachment" "vm" {
  vpc_id    = ibee_vpc.main.id
  subnet_id = ibee_vpc_subnet.apps.id
  vm_id     = var.vm_id
}

output "private_ip" {
  value = ibee_vpc_node_attachment.vm.private_ip
}
