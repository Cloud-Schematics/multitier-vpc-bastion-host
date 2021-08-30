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

# unique name for the project to use as prefix
variable "prj" {
  description = "Name of active project"
  default     = "broy"
}

# unique name for the environment to use as prefix
variable "active_envionment" {
  description = "Name of active environment"
  default     = "dev"
}


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
  type        = list(any)
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

variable "datagov_cidr" {
  description = "Complete CIDR range across all three zones for data gov subnets"
  default     = "172.18.0.0/20"
}


##############################################################################
# VSI profile
##############################################################################

# RHEL Profile
variable "profile" {
  description = "Default RHEL Profile for VSIs deployed in all tiers"
  default     = "bx2-2x8"
}
# image names can be determined with the cli command `ibmcloud is images`
variable "image_name" {
  description = "Default RHEL 7 image for VSI deployments."
  default     = "ibm-redhat-7-9-minimal-amd64-3"
}
data "ibm_is_image" "os" {
  name = var.image_name
}

# Windows Profile
variable "win_profile" {
  description = "MS Windows profile for VSIs deployed in all tiers"
  default     = "bx2-4x16"
}
# image names can be determined with the cli command `ibmcloud is images`
variable "win_image_name" {
  description = "Windows OS image for VSI deployments"
  default     = "ibm-windows-server-2019-full-standard-amd64-3"
}
data "ibm_is_image" "win_os" {
  name = var.win_image_name
}

# Satellite
variable "sat_profile" {
  description = "Default RHEL Profile for satellite"
  default     = "bx2-16x64"
}
# image names can be determined with the cli command `ibmcloud is images`
variable "sat_image_name" {
  description = "Defaults to default RHEL VSI os image"
  default     = "ibm-redhat-7-9-minimal-amd64-3"
}
data "ibm_is_image" "sat_os" {
  name = var.sat_image_name
}

# Cognos
variable "cog_profile" {
  description = "Default RHEL Profile for Cognos servers"
  default     = "mx2d-8x64"
}
# image names can be determined with the cli command `ibmcloud is images`
variable "cog_image_name" {
  description = "Defaults to RHEL 8 VSI deployments"
  default     = "ibm-redhat-8-3-minimal-amd64-3"
}
data "ibm_is_image" "cog_os" {
  name = var.cog_image_name
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

variable "ssh_key_name" {
  description = "Name giving to public SSH key uploaded to IBM Cloud for VSI access"
  default = "broy-bastion-psm-host"
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}