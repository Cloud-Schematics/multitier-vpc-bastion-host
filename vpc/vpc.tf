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



resource "ibm_is_vpc_address_prefix" "frontend_subnet_prefix" {
  count = var.frontend_count
  name  = "${var.unique_id}-frontend-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.frontend_cidr_blocks[count.index]

}

resource "ibm_is_vpc_address_prefix" "backend_subnet_prefix" {
  count = var.backend_count
  name  = "${var.unique_id}-backend-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.backend_cidr_blocks[count.index]
}

resource "ibm_is_vpc_address_prefix" "datagov_subnet_prefix" {
  count = var.datagov_count
  name  = "${var.unique_id}-datagov-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.datagov_cidr_blocks[count.index]
}

##############################################################################

##############################################################################
# Create Subnets
##############################################################################

# Increase count to create subnets in all zones
resource "ibm_is_subnet" "frontend_subnet" {
  count           = var.frontend_count
  name            = "${var.unique_id}-frontend-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.frontend_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.frontend_subnet_prefix]
}

# Increase count to create subnets in all zones
resource "ibm_is_subnet" "backend_subnet" {
  count           = var.backend_count
  name            = "${var.unique_id}-backend-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.backend_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.backend_subnet_prefix]
}

resource "ibm_is_subnet" "datagov_subnet" {
  count           = var.datagov_count
  name            = "${var.unique_id}-datagov-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.datagov_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.datagov_subnet_prefix]
}



# Increase count to create gateways in all zones
resource "ibm_is_public_gateway" "repo_gateway" {
  count = var.frontend_count
  name  = "${var.unique_id}-public-gtw-${count.index}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

#############################################################################






#############################################################################
# Enable Flow logs
#############################################################################

module "vpc_flow_log" {
  source                   = "..modules/flowlogs"
  unique_id                = ibm_is_vpc.vpc.name
  ibm_region               = var.ibm_region
  ibm_is_vpc_id            = ibm_is_vpc.vpc.id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  ibm_is_res_target_id     = ibm_is_vpc.vpc.id

}



#############################################################################