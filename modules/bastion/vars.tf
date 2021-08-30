##############################################################################
# Bastion host VPC input variables
##############################################################################

variable "unique_id" {
} # string added to the front for all created resources

# create resources in this vpc id
variable "ibm_is_vpc_id" {
}

# create resources in this resource group id
variable "ibm_is_resource_group_id" {
}

##############################################################################
# Bastion host VSI variables
##############################################################################

# VSI compute profile for bastion host
variable "vsi_profile" {
  default = "cx2-2x4"
}

# VSI image name
variable "image_name" {
  description = "Bastion host config scripts have only been tested with Centos"
  default     = "ibm-centos-7-6-minimal-amd64-1"
}

data "ibm_is_image" "os" {
  name = var.image_name
}

variable "ssh_key_id" {
  description = "ID of IBM Cloud SSH key to be used for bastion host"
}

# 
variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
  default     = "us-south"
}

# variable "az_list" {
#   description = "IBM Cloud availability zones for region"
#   default     = ["us-south-1", "us-south-2", "us-south-3"]
# }

variable "bastion_count" {
  description = "Number of MZR zones bastions will be created in. First bastion is in Zone 1 "
  default     = 1
}

##############################################################################
# Network variables
##############################################################################

variable "bastion_cidr" {
  description = "CIDR for range of bastion zone subnets"
}

# All CIDR blocks of servers connectinhg to the bastion host
# To limit total number of rules in ACL, restrict number of source CIDRs to 4. For a total of 8 ACL rules 
variable "ssh_source_cidr_blocks" {
  description = "Public Source CIDRs"
  default     = []
}

# remote subnets bastion will egress to (frontend, backend)
# To limit total number of rules in ACL to under 25, use single CIDR range across all zones per SG 
# CIDR per zone exceeds number of allowed ACL rules
variable "destination_cidr_blocks" {
  description = "CIDRs of destination private subnets in VPC"
  default     = []
}

# remote security groups bastion will egress to (frontend, backend)
variable "destination_sgs" {
  description = "Destination Security Groups in VPC"
  default     = []
}

# Allow user to pass in additional rules e.g. icmp
variable "extrarules" {
  description = "Additional rules supplied by user"
  default = [
    #["allow", "0.0.0.0/0", "0.0.0.0/0", "inbound", "tcp", 1024, 65535, 22, 22],
    #["allow", "0.0.0.0/0", "0.0.0.0/0", "outbound", "tcp", 22, 22, 1024, 65535]
  ]
}
