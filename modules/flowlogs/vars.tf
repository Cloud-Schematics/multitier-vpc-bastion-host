variable "unique_id" {
} # string added to the front for all created resources

variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
  default     = "us-south"
}

# create resources in this vpc id
variable "ibm_is_vpc_id" {
}

# create resources in this resource group id
variable "ibm_is_resource_group_id" {
}

# Target is an instance, subnet, or VPC, flow logs is not collected for any network
# interfaces within the target that are more specific flow log collector.
variable "ibm_is_res_target_id" {
    description = "The ID of the target to collect flow logs"
}

# COS Plan selected for Flow Logs
variable "ibm_res_cos_plan" {
    description = "Default plan for IBM Cloud Object Storage"
    default = "standard"
}