##############################################################################
# Account Variables
##############################################################################

# target region
variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
  default     = "us-south"
  # default     = "us-east"
  # default     = "eu-gb"
}

# variable "ibmcloud_api_key" {
#   description = "IBM Cloud API key when run standalone"
# }



variable "resource_group_name" {
  description = "Name of IBM Cloud Resource Group used for all VPC resources"
  default     = "Default"
}

# #Only tested with Gen2. Gen1 requires changes to images, profile names and some VPC resources 
# variable "generation" {
#   description = "VPC generation. Only tested with VPC Gen2"
#   default     = 2
# }

# unique name for the VPC in the account 
variable "vpc_name" {
  description = "Name of vpc"
  default     = "ssh-bastion-host"
}

##############################################################################

##############################################################################
# Network variables
##############################################################################

# When running under Schematics the default here is overriden to only SSH access 
# from remove-exec or Redhat Ansible running under Schematics 

variable "ssh_source_cidr_override" {
  type        = list
  description = "Override CIDR range that is allowed to ssh to the bastion"
  default     = ["0.0.0.0/0"]
}


locals {
  pub_repo_egress_cidr = "0.0.0.0/0" # cidr range required to contact public software repositories 
}

# Predefine subnets for all app tiers for use with `ibm_is_address_prefix`. Single tier CIDR used for NACLs  
# Each app tier uses: 
# frontend_cidr_blocks = [cidrsubnet(var.frontend_cidr, 4, 0), cidrsubnet(var.frontend_cidr, 4, 2), cidrsubnet(var.frontend_cidr, 4, 4)]
# to create individual zone subnets for use with `ibm_is_address_prefix`
variable "bastion_cidr" {
  description = "Complete CIDR range across all three zones for bastion host subnets"
  default     = "172.22.192.0/20"
}

variable "frontend_cidr" {
  description = "Complete CIDR range across all three zones for frontend subnets"
  default     = "172.16.0.0/20"
}

variable "backend_cidr" {
  description = "Complete CIDR range across all three zones for backend subnets"
  default     = "172.17.0.0/20"
}


##############################################################################

# VSI profile
variable "profile" {
  description = "Profile for VSIs deployed in frontend and backend"
  default     = "cx2-2x4"
}

# image names can be determined with the cli command `ibmcloud is images`
variable "image_name" {
  description = "OS image for VSI deployments. Only tested with Centos"
  default     = "ibm-centos-7-6-minimal-amd64-1"
}

data "ibm_is_image" "os" {
  name = var.image_name
}


##############################################################################
# Access check variables
##############################################################################

variable "ssh_accesscheck" {
  description = "Flag to request remote-exec validation of SSH access, true/false"
  default     = false
}

variable "ssh_private_key" {
  description = "SSH private key of SSH key pair used for VSIs and Bastion"
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

variable "ssh_key_name" {
  description = "Name giving to public SSH key uploaded to IBM Cloud for VSI access"
}

