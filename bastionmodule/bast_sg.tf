
##############################################################################
# Config to dynamically create bastion host Security Group and rules
#
# Base rules for access to DNS, repos are predefined. Inputs required for 
# target SG's bastion host will connect to and the source CIDRs of the servers
# that will connect via the bastion host
##############################################################################



# this is the SG applied to the bastion instance
resource "ibm_is_security_group" "bastion" {
  name           = "${var.unique_id}-bastion-sg"
  vpc            = var.ibm_is_vpc_id
  resource_group = var.ibm_is_resource_group_id
}


locals {
  sg_keys = ["direction", "remote", "type", "port_min", "port_max"]

  # base rules for maintenance repo's, DNS 
  sg_baserules = [
    ["outbound", "161.26.0.0/16", "udp", 53, 53],
    ["outbound", "161.26.0.0/16", "tcp", 80, 80],
    ["outbound", "161.26.0.0/16", "tcp", 443, 443],
  ]

  sg_sourcerules = [
    for entry in var.ssh_source_cidr_blocks :
    ["inbound", entry, "tcp", 22, 22]
  ]

  sg_destrules = [
    for entry in var.destination_sgs :
    ["outbound", entry, "tcp", 22, 22]
  ]


  #concatinate all sources of rules
  sg_rules = concat(local.sg_sourcerules, local.sg_destrules, local.sg_baserules)
  sg_mappedrules = [
    for entry in local.sg_rules :
    merge(zipmap(local.sg_keys, entry))
  ]
}


output "list_sg_rules" {
  value = local.sg_mappedrules
}

resource "ibm_is_security_group_rule" "bastion_access" {
  count     = length(local.sg_mappedrules)
  group     = ibm_is_security_group.bastion.id
  direction = (local.sg_mappedrules[count.index]).direction
  remote    = (local.sg_mappedrules[count.index]).remote
  dynamic "tcp" {
    for_each = local.sg_mappedrules[count.index].type == "tcp" ? [
      {
        port_max = local.sg_mappedrules[count.index].port_max
        port_min = local.sg_mappedrules[count.index].port_min
      }
    ] : []
    content {
      port_max = tcp.value.port_max
      port_min = tcp.value.port_min

    }
  }
  dynamic "udp" {
    for_each = local.sg_mappedrules[count.index].type == "udp" ? [
      {
        port_max = local.sg_mappedrules[count.index].port_max
        port_min = local.sg_mappedrules[count.index].port_min
      }
    ] : []
    content {
      port_max = udp.value.port_max
      port_min = udp.value.port_min
    }
  }
  dynamic "icmp" {
    for_each = local.sg_mappedrules[count.index].type == "icmp" ? [
      {
        type = local.sg_mappedrules[count.index].port_max
        code = local.sg_mappedrules[count.index].port_min
      }
    ] : []
    content {
      type = icmp.value.type
      code = icmp.value.code
    }
  }
}



