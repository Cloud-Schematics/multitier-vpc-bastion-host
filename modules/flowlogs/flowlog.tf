##############################################################################
# This file creates flow log for any given resource. 
# All logs are assumed to go in the same global cos instance. In case aother
# instance is supposed to be used 
##############################################################################

# Instance Details
resource "ibm_resource_instance" "flowlog_cos_instance" {
  name              = "flowlog-cos-instance"
  resource_group_id = var.ibm_is_resource_group_id
  service           = "cloud-object-storage"
  plan              = var.ibm_res_cos_plan
  location          = "global"
}

# Bucket specific to the resource
resource "ibm_cos_bucket" "cos_bucket" {
  bucket_name          = "${var.unique_id}-cos-flowlog"
  resource_instance_id = ibm_resource_instance.flowlog_cos_instance.id
  storage_class        = var.ibm_res_cos_plan
  region_location      = var.ibm_region
}

# There are flow logs that may or may not need dependency check
resource "ibm_is_flow_log" "res_flowlog" {
  # check if there is dependency
  # depends_on = ibm_is_vpc.VPC
  name   = "${var.unique_id}-flow-log"
  target = var.ibm_is_res_target_id
  # active = true
  storage_bucket = ibm_cos_bucket.cos_bucket.bucket_name
}
