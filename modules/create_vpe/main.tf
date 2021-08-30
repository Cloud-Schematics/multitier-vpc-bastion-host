resource "ibm_is_virtual_endpoint_gateway" "vpe" {
  for_each = { for target in var.endpoints : target.name => target }

  name           = "${var.basename}-${each.key}-vpe"
  resource_group = var.resource_group_id
  vpc            = var.vpc_id

  target {
    crn           = each.value.crn
    resource_type = "provider_cloud_service"
  }

  # one Reserved IP for per zone in the VPC
  dynamic "ips" {
    for_each = { for subnet in var.subnets : subnet.id => subnet }
    content {
      subnet = ips.key
      name   = "${ips.value.name}-${each.key}-ip"
    }
  }

  tags = var.tags
}