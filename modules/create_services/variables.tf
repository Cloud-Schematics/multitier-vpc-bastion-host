variable "basename" {
  type = string
}

variable "region" {
  type    = string
  default = "us-south"
}

variable "resource_group_id" {
  type = string
}

variable "tags" {
  type = list(string)
}

variable "create_logging" {
  type        = bool
  default     = false
  description = "Create a logging instance in the region and resource group provided above"
}

variable "create_monitoring" {
  type        = bool
  default     = false
  description = "Create a monitoring instance in the region and resource group provided above"
}