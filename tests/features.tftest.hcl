# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details            = { scope = "Test", purpose = "Features", environment = "test" }
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
}

run "every_option_on" {
  command = plan
  variables {
    attachment = {
      dns_support                        = false
      ipv6_support                       = true
      appliance_mode_support             = true
      security_group_referencing_support = true
      default_route_table_association    = false
      default_route_table_propagation    = true
      name                               = "shared-services"
    }
  }
  assert {
    condition = alltrue([
      aws_ec2_transit_gateway_vpc_attachment.this.dns_support == "disable",
      aws_ec2_transit_gateway_vpc_attachment.this.ipv6_support == "enable",
      aws_ec2_transit_gateway_vpc_attachment.this.appliance_mode_support == "enable",
      aws_ec2_transit_gateway_vpc_attachment.this.security_group_referencing_support == "enable",
      aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_default_route_table_association == false,
      aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_default_route_table_propagation == true,
      aws_ec2_transit_gateway_vpc_attachment.this.tags["Name"] == "shared-services",
    ])
    error_message = "Each option must reach the attachment."
  }
}

# Routes of each destination type, in two route tables, all to the transit gateway.
run "routes" {
  command = apply
  variables {
    routes = {
      a_private = { route_table_id = "rtb-0000000000000000a", destination_cidr_block = "10.0.0.0/8" }
      b_private = { route_table_id = "rtb-0000000000000000b", destination_cidr_block = "10.0.0.0/8" }
      a_ipv6    = { route_table_id = "rtb-0000000000000000a", destination_ipv6_cidr_block = "2600:1f18:1234:5600::/56" }
      a_list    = { route_table_id = "rtb-0000000000000000a", destination_prefix_list_id = "pl-0123456789abcdef0" }
    }
  }
  assert {
    condition = alltrue([
      length(aws_route.this) == 4,
      alltrue([for r in aws_route.this : r.transit_gateway_id == "tgw-0123456789abcdef0"]),
      aws_route.this["b_private"].route_table_id == "rtb-0000000000000000b",
      aws_route.this["a_private"].destination_cidr_block == "10.0.0.0/8",
      aws_route.this["a_private"].destination_ipv6_cidr_block == null,
      aws_route.this["a_ipv6"].destination_ipv6_cidr_block == "2600:1f18:1234:5600::/56",
      aws_route.this["a_ipv6"].destination_cidr_block == null,
      aws_route.this["a_list"].destination_prefix_list_id == "pl-0123456789abcdef0",
      output.metadata.route["a_list"].transit_gateway_id == "tgw-0123456789abcdef0",
      keys(output.metadata.route) == ["a_ipv6", "a_list", "a_private", "b_private"],
    ])
    error_message = "Each route must go to the transit gateway with its own destination."
  }
}

# Subnets are changed in place, without replacing the attachment.
run "change_subnets" {
  command = plan
  variables {
    subnet_ids = ["subnet-0000000000000000a", "subnet-0000000000000000c"]
  }
  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this.id == run.routes.metadata.vpc_attachment.id
    error_message = "Changing subnet_ids must not replace the attachment."
  }
}
