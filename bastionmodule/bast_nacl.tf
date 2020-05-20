
##############################################################################
# Config to dynamically create bastion host Network ACL and rules
#
# Base rules for access to DNS, repos are predefined. Inputs required for 
# target subnets bastion host will connect to and the source CIDRs of the servers
# that will connect via the bastion host
##############################################################################




# Generate rules for limiting access to SSH public source subnets/CIDRs 
# and IBM Cloud private destination subnets/CIDRs
locals {
  destinboundrules = [
    for entry in var.destination_cidr_blocks :
    ["allow", entry, "0.0.0.0/0", "inbound", "tcp", 22, 22, 1024, 65535]
  ]
  destoutboundrules = [
    for entry in var.destination_cidr_blocks :
    ["allow", "0.0.0.0/0", entry, "outbound", "tcp", 1024, 65535, 22, 22]
  ]
  destrules = concat(local.destinboundrules, local.destoutboundrules)

  sourceinboundrules = [
    for entry in var.ssh_source_cidr_blocks :
    ["allow", entry, "0.0.0.0/0", "inbound", "tcp", 1024, 65535, 22, 22]
  ]
  sourceoutboundrules = [
    for entry in var.ssh_source_cidr_blocks :
    ["allow", "0.0.0.0/0", entry, "outbound", "tcp", 22, 22, 1024, 65535]
  ]
  sourcerules = concat(local.sourceinboundrules, local.sourceoutboundrules)
}

# output "list_frontend" {
#   value = local.destrules
# }

# output "list_source" {
#   value = local.sourcerules
# }


locals {
  keys = ["action", "source", "destination", "direction", "type", "source_port_min", "source_port_max", "port_min", "port_max"]

  # base rules for maintenance repo's, DNS and Deny all. 
  # note deny rules explicitly defined as tcp/udp as 'all' not supported when this was written
  baserules = [
    ["allow", "161.26.0.0/16", "0.0.0.0/0", "inbound", "tcp", 80, 80, 1024, 65535],
    ["allow", "161.26.0.0/16", "0.0.0.0/0", "inbound", "udp", 53, 53, 1024, 65535],
    ["allow", "0.0.0.0/0", "161.26.0.0/16", "outbound", "tcp", 1024, 65535, 80, 80],
    ["allow", "0.0.0.0/0", "161.26.0.0/16", "outbound", "udp", 1024, 65535, 53, 53],
    #["allow", "166.9.0.0/16", "0.0.0.0/0", "inbound", "tcp", 1, 65535, 1024, 65535],
    #["allow", "0.0.0.0/0", "166.9.0.0/16", "outbound", "tcp", 1024, 65535, 1, 65535],
    ["deny", "0.0.0.0/0", "0.0.0.0/0", "inbound", "all", 1, 65535, 1, 65535],
    ["deny", "0.0.0.0/0", "0.0.0.0/0", "outbound", "all", 1, 65535, 1, 65535],
  ]

  #concatinate all sources of rules
  # max rules is 25, focus is on denying external traffic access to subnets in case of SG misconfiguration
  rules = concat(var.extrarules, local.destrules, local.sourcerules, local.baserules)

  mappedrules = [
    for entry in local.rules :
    merge(zipmap(local.keys, entry))
  ]
}


# merge in random names of rules 
resource "random_string" "uuid" {
  count   = length(local.rules)
  special = false
  number  = false
  lower   = true
  upper   = false
  length  = 8
}

locals {
  randlist = random_string.uuid[*].id

  rulesmerge = [
    for i, entry in local.mappedrules :
    merge(entry, { "name" = "${entry.direction}-${entry.type}-${local.randlist[i]}" })
  ]
}

# output "list_nacl_rules" {
#   value = local.rulesmerge
# }

resource "ibm_is_network_acl" "bastion_acl" {
  name           = "${var.unique_id}-bastion-acl"
  vpc            = var.ibm_is_vpc_id
  resource_group = var.ibm_is_resource_group_id
  dynamic "rules" {
    for_each = [for i in local.rulesmerge :
      {
        name            = i.name
        action          = i.action
        source          = i.source
        destination     = i.destination
        direction       = i.direction
        source_port_min = i.source_port_min
        source_port_max = i.source_port_max
        port_min        = i.port_min
        port_max        = i.port_max
        type            = i.type
      }
    ]
    content {
      name        = rules.value.name
      action      = rules.value.action
      source      = rules.value.source
      destination = rules.value.destination
      direction   = rules.value.direction
      dynamic "tcp" {
        for_each = rules.value.type == "tcp" ? [
          {
            port_max        = rules.value.port_max
            port_min        = rules.value.port_min
            source_port_max = rules.value.source_port_max
            source_port_min = rules.value.source_port_min
          }
        ] : []
        content {
          port_max        = tcp.value.port_max
          port_min        = tcp.value.port_min
          source_port_max = tcp.value.source_port_max
          source_port_min = tcp.value.source_port_min
        }
      }
      dynamic "udp" {
        for_each = rules.value.type == "udp" ? [
          {
            port_max        = rules.value.port_max
            port_min        = rules.value.port_min
            source_port_max = rules.value.source_port_max
            source_port_min = rules.value.source_port_min
          }
        ] : []
        content {
          port_max        = udp.value.port_max
          port_min        = udp.value.port_min
          source_port_max = udp.value.source_port_max
          source_port_min = udp.value.source_port_min
        }
      }
      dynamic "icmp" {
        for_each = rules.value.type == "icmp" ? [
          {
            code = rules.value.port_max
            type = rules.value.port_min
          }
        ] : []
        content {
          code = icmp.value.code
          type = icmp.value.type
        }
      }
    }
  }
}
