# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The attachment of the VPC to the transit gateway, in the subnets listed. Every option is
# set explicitly, so the plan shows what AWS will configure.
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  region = var.region

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  dns_support                        = var.attachment.dns_support ? "enable" : "disable"
  ipv6_support                       = var.attachment.ipv6_support ? "enable" : "disable"
  appliance_mode_support             = var.attachment.appliance_mode_support ? "enable" : "disable"
  security_group_referencing_support = var.attachment.security_group_referencing_support ? "enable" : "disable"

  # null leaves the choice to the transit gateway's own default route table settings.
  transit_gateway_default_route_table_association = var.attachment.default_route_table_association
  transit_gateway_default_route_table_propagation = var.attachment.default_route_table_propagation

  tags = merge(local.tags, { Name = local.attachment_name })
}
