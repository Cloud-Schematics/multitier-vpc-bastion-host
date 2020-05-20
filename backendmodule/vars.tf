variable "unique_id" {
} # string added to the front for all created resources

# create resources in this vpc id
variable "ibm_is_vpc_id" {
}

# create resources in this resource group id
variable "ibm_is_resource_group_id" {
}

variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
  default     = "us-south"
}

# VSI compute profile for webserver host
variable "profile" {
}

# Id of VSI image 
variable "ibm_is_image_id" {
}

# SSH key for backend webservers. 
variable "ibm_is_ssh_key_id" {
}

# webserver instance is put in this subnet
variable "subnet_ids" {
}

variable "app_frontend_sg_id" {
}

# bastion sg requiring access to backend security group
variable "bastion_remote_sg_id" {
}

# bastion subnet CIDR requiring access to backend subnets 
variable "bastion_subnet_CIDR" {
}

# Allowable CIDRs of public repos from which Ansible can deploy code
variable "pub_repo_egress_cidr" {
}

variable "backend_count" {
  description = "number of back end zones"
  default     = 1
}
