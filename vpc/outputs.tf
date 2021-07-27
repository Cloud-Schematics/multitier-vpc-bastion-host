output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "blue_subnet_ids" {
  value = ibm_is_subnet.blue_subnet.*.id
}

output "green_subnet_ids" {
  value = ibm_is_subnet.green_subnet.*.id
}
