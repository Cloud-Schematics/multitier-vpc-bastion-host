output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "frontend_subnet_ids" {
  value = ibm_is_subnet.frontend_subnet.*.id
}

output "datgov_subnet_ids" {
  value = ibm_is_subnet.datgov_subnet.*.id
}

output "backend_subnet_ids" {
  value = ibm_is_subnet.backend_subnet.*.id
}
