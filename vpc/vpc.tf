##############################################################################
# This file creates the VPC, Zones, subnets, acls and public gateway for the 
# example VPC. It is not intended to be a full working application 
# environment. 
#
# Separately setup up any required load balancers, listeners, pools and members
##############################################################################

##############################################################################
# Create a VPC
##############################################################################
data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name                      = var.unique_id
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

##############################################################################






##############################################################################
# Prefixes and subnets for zone 1
##############################################################################



resource "ibm_is_vpc_address_prefix" "blue_subnet_prefix" {
  count = var.blue_count
  name  = "${var.unique_id}-blue-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.blue_cidr_blocks[count.index]

}

resource "ibm_is_vpc_address_prefix" "green_subnet_prefix" {
  count = var.green_count
  name  = "${var.unique_id}-green-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.green_cidr_blocks[count.index]
}

##############################################################################

##############################################################################
# Create Subnets
##############################################################################




# Increase count to create subnets in all zones
resource "ibm_is_subnet" "blue_subnet" {
  count           = var.blue_count
  name            = "${var.unique_id}-blue-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.blue_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.blue_subnet_prefix]
}

# Increase count to create subnets in all zones
resource "ibm_is_subnet" "green_subnet" {
  count           = var.green_count
  name            = "${var.unique_id}-green-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.green_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.green_subnet_prefix]
}





# Increase count to create gateways in all zones
resource "ibm_is_public_gateway" "repo_gateway" {
  count = var.blue_count
  name  = "${var.unique_id}-public-gtw-${count.index}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}





#############################################################################




