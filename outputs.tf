# Single value, pending support for multiple output values in schematics_workspace_putputs data source
output "bastion_host_ip_address" {
  value = module.bastion.bastion_ip_addresses[0]
}

# output "bastion_host_ip_addresses" {
#   value = module.bastion.bastion_ip_addresses
# }

output "blue_server_host_ip_addresses" {
  value = [module.blue.primary_ipv4_address]
}

output "green_server_host_ip_addresses" {
  value = [module.green.primary_ipv4_address]
}

output "app_dns_hostname" {
  value = module.blue.lb_hostname
}



