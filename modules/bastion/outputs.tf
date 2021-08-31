##############################################################################
# Bastion host output variables. 
#
# Ouputs required as input to SG and Subnet configs that require bastion access 
##############################################################################


# public (floating) IP address attached to the bastion hosts. Ordered by zone attachment. 
output "bastion_ip_addresses" {
  value = ibm_is_floating_ip.bastion.*.address
}

# bastion security group. Add this as the remote SG to all instances that require SSH access from the bastion
output "security_group_id" {
  value = ibm_is_security_group.bastion.id
}

# Allocated bastion subnets. 
output "bastion_subnet_ids" {
  value = ibm_is_subnet.bastion_subnet.*.id
}
