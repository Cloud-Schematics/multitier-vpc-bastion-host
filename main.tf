
# provider block required with Schematics to set VPC region
provider "ibm" {
  region = var.ibm_region
  #ibmcloud_api_key = var.ibmcloud_api_key
  generation = local.generation
  version    = "~> 1.4"
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

locals {
  generation     = 2
  frontend_count = 2
  backend_count  = 1
}


##################################################################################################
#  Select CIDRs allowed to access bastion host  
#  When running under Schematics allowed ingress CIDRs are set to only allow access from Schematics  
#  for use with Remote-exec and Redhat Ansible
#  When running under Terraform local execution ingress is set to 0.0.0.0/0
#  Access CIDRs are overridden if user_bastion_ingress_cidr is set to anything other than "0.0.0.0/0" 
##################################################################################################


data "external" "env" { program = ["jq", "-n", "env"] }
locals {
  region = lookup(data.external.env.result, "TF_VAR_SCHEMATICSLOCATION", "")
  geo    = substr(local.region, 0, 2)
  schematics_ssh_access_map = {
    us = ["169.44.0.0/14", "169.60.0.0/14"],
    eu = ["158.175.0.0/16","158.176.0.0/15","141.125.75.80/28","161.156.139.192/28","149.81.103.128/28"],
  }
  schematics_ssh_access = lookup(local.schematics_ssh_access_map, local.geo, ["0.0.0.0/0"])
  bastion_ingress_cidr  = var.ssh_source_cidr_override[0] != "0.0.0.0/0" ? var.ssh_source_cidr_override : local.schematics_ssh_access
}


module "vpc" {
  source               = "./vpc"
  ibm_region           = var.ibm_region
  resource_group_name  = var.resource_group_name
  generation           = local.generation
  unique_id            = var.vpc_name
  frontend_count       = local.frontend_count
  frontend_cidr_blocks = local.frontend_cidr_blocks
  backend_count        = local.backend_count
  backend_cidr_blocks  = local.backend_cidr_blocks
}

locals {
  # bastion_cidr_blocks  = [cidrsubnet(var.bastion_cidr, 4, 0), cidrsubnet(var.bastion_cidr, 4, 2), cidrsubnet(var.bastion_cidr, 4, 4)]
  frontend_cidr_blocks = [cidrsubnet(var.frontend_cidr, 4, 0), cidrsubnet(var.frontend_cidr, 4, 2), cidrsubnet(var.frontend_cidr, 4, 4)]
  backend_cidr_blocks  = [cidrsubnet(var.backend_cidr, 4, 0), cidrsubnet(var.backend_cidr, 4, 2), cidrsubnet(var.backend_cidr, 4, 4)]
}


# Create single zone bastion
module "bastion" {
  source                   = "./bastionmodule"
  ibm_region               = var.ibm_region
  bastion_count            = 1
  unique_id                = var.vpc_name
  ibm_is_vpc_id            = module.vpc.vpc_id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  bastion_cidr             = var.bastion_cidr
  ssh_source_cidr_blocks   = local.bastion_ingress_cidr
  destination_cidr_blocks  = [var.frontend_cidr, var.backend_cidr]
  destination_sgs          = [module.frontend.security_group_id, module.backend.security_group_id]
  # destination_sg          = [module.frontend.security_group_id, module.backend.security_group_id]
  # vsi_profile             = "cx2-2x4"
  # image_name              = "ibm-centos-8-3-minimal-amd64-3"
  ssh_key_id = data.ibm_is_ssh_key.sshkey.id

}


module "frontend" {
  source                   = "./frontendmodule"
  ibm_region               = var.ibm_region
  unique_id                = var.vpc_name
  ibm_is_vpc_id            = module.vpc.vpc_id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  frontend_count           = local.frontend_count
  profile                  = var.profile
  ibm_is_image_id          = data.ibm_is_image.os.id
  ibm_is_ssh_key_id        = data.ibm_is_ssh_key.sshkey.id
  subnet_ids               = module.vpc.frontend_subnet_ids
  bastion_remote_sg_id     = module.bastion.security_group_id
  bastion_subnet_CIDR      = var.bastion_cidr
  pub_repo_egress_cidr     = local.pub_repo_egress_cidr
  app_backend_sg_id        = module.backend.security_group_id
}

module "backend" {
  source                   = "./backendmodule"
  ibm_region               = var.ibm_region
  unique_id                = var.vpc_name
  ibm_is_vpc_id            = module.vpc.vpc_id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  backend_count            = local.backend_count
  profile                  = var.profile
  ibm_is_image_id          = data.ibm_is_image.os.id
  ibm_is_ssh_key_id        = data.ibm_is_ssh_key.sshkey.id
  subnet_ids               = module.vpc.backend_subnet_ids
  bastion_remote_sg_id     = module.bastion.security_group_id
  bastion_subnet_CIDR      = var.bastion_cidr
  app_frontend_sg_id       = module.frontend.security_group_id
  pub_repo_egress_cidr     = local.pub_repo_egress_cidr
}

module "accesscheck" {
  source          = "./accesscheck"
  ssh_accesscheck = var.ssh_accesscheck
  ssh_private_key = var.ssh_private_key
  bastion_host    = module.bastion.bastion_ip_addresses[0]
  target_hosts    = concat(module.frontend.primary_ipv4_address, module.backend.primary_ipv4_address)
}
