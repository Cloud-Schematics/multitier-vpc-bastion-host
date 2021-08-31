variable "basename" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "endpoints" {
  type = any
}

variable "subnets" {
  type = any
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "vpc-scaling"]
}
