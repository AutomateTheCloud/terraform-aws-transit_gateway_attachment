# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Bugs in the module before 1.0.0, each shown with a mocked test before it was fixed.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details            = { scope = "Test", purpose = "Regressions", environment = "test" }
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
}

# The attachment ignored subnet_ids: it used every subnet of the VPC tagged
# Network = private, found with a data source, which could hold two subnets in one
# Availability Zone (AWS rejects that) and missed subnets created in the same run. The
# attachment now uses exactly the subnets listed.
run "attachment_uses_the_listed_subnets" {
  command = plan
  variables { subnet_ids = ["subnet-0000000000000000c"] }
  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids == toset(["subnet-0000000000000000c"])
    error_message = "The attachment must use exactly the subnets listed."
  }
}

# Routes were a list indexed by position: removing the first destination moved the
# second to index 0, so every route after it was replaced. Keyed by name, removing one
# leaves the others alone.
run "two_routes" {
  command = apply
  variables {
    routes = {
      ten           = { route_table_id = "rtb-0000000000000000a", destination_cidr_block = "10.0.0.0/8" }
      one_seven_two = { route_table_id = "rtb-0000000000000000a", destination_cidr_block = "172.16.0.0/12" }
    }
  }
}

run "remove_one_route_keeps_the_other" {
  command = plan
  variables {
    routes = {
      one_seven_two = { route_table_id = "rtb-0000000000000000a", destination_cidr_block = "172.16.0.0/12" }
    }
  }
  assert {
    condition = alltrue([
      keys(aws_route.this) == ["one_seven_two"],
      aws_route.this["one_seven_two"].id == run.two_routes.metadata.route["one_seven_two"].id,
    ])
    error_message = "Removing one route must not change the other."
  }
}

# The Name tag was built from the transit gateway's description and the VPC's Name tag,
# read with data sources: with neither set it was " - vpc-0123456789abcdef0 ()". It now
# comes from details, and the module reads no transit gateway and no VPC.
run "name_from_details" {
  command = plan
  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this.tags["Name"] == "test-regressions-test-use1"
    error_message = "Unexpected Name tag."
  }
}

# routes_to_populate was required, so the module could not attach a VPC without adding
# routes. Routes are now optional.
run "no_routes" {
  command = plan
  assert {
    condition     = length(aws_route.this) == 0
    error_message = "Expected no routes."
  }
}
