# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A route to the transit gateway for each entry in var.routes. for_each uses the map keys,
# which come from the inputs, so a route table created in the same run still plans, and
# removing one route leaves the others alone. The transit gateway ID is taken from the
# attachment, so each route is created only once the VPC is attached.
resource "aws_route" "this" {
  for_each = var.routes
  region   = var.region

  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block
  destination_prefix_list_id  = each.value.destination_prefix_list_id
  transit_gateway_id          = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_id
}
