
output security_group_id {
  value = ibm_is_security_group.datagov.id
}

output primary_ipv4_address {
  value = ibm_is_instance.datagov-server[*].primary_network_interface[0].primary_ipv4_address
}
