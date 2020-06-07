
##############################################################################
# This file creates the Bastion host, subnet and security group. NACL and
# Security Group rules are created in nacl.tf and sg_rules.tf respectively.  
#
# All resources required to configure secure SSH access via a bastion host to 
# VSIs in a VPC are contained within this module. The module can be used with 
# the associated VPC module or used to add bastion host functionality to 
# other VPC configurations  
##############################################################################


resource "ibm_is_instance" "bastion" {
  count   = var.bastion_count
  name    = "${var.unique_id}-bastion-vsi-${count.index + 1}"
  image   = data.ibm_is_image.os.id
  profile = var.vsi_profile

  primary_network_interface {
    subnet          = ibm_is_subnet.bastion_subnet[count.index].id
    security_groups = [ibm_is_security_group.bastion.id]
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  vpc            = var.ibm_is_vpc_id
  zone           = "${var.ibm_region}-${count.index % 3 + 1}"
  resource_group = var.ibm_is_resource_group_id
  keys           = [var.ssh_key_id]
  user_data      = file("${path.module}/bastion_config.yml")
  tags           = ["schematics:bastion"]
}

resource "ibm_is_floating_ip" "bastion" {
  count  = var.bastion_count
  name   = "${var.unique_id}-float-bastion-ip-${count.index + 1}"
  target = ibm_is_instance.bastion[count.index].primary_network_interface[0].id
}


# Define individual subnets for address_prefix
locals {
  bastion_prefix = [cidrsubnet(var.bastion_cidr, 4, 0), cidrsubnet(var.bastion_cidr, 4, 2), cidrsubnet(var.bastion_cidr, 4, 4)]
}

resource "ibm_is_vpc_address_prefix" "bast_subnet_prefix" {
  count = var.bastion_count
  name  = "${var.unique_id}-bast-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = var.ibm_is_vpc_id
  cidr  = local.bastion_prefix[count.index]
}

# Single subnet for singe zone bastion
resource "ibm_is_subnet" "bastion_subnet" {
  count           = var.bastion_count
  name            = "${var.unique_id}-bast-subnet-${count.index + 1}"
  vpc             = var.ibm_is_vpc_id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = ibm_is_vpc_address_prefix.bast_subnet_prefix.*.cidr[count.index]
  resource_group  = var.ibm_is_resource_group_id
  network_acl     = ibm_is_network_acl.bastion_acl.id
  depends_on      = [ibm_is_vpc_address_prefix.bast_subnet_prefix]
}




