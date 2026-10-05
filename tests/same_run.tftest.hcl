# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The transit gateway, VPC, subnets and route table come from resources in the same run.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_ec2_transit_gateway" {
    defaults = { id = "tgw-0123456789abcdef0" }
  }
  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_resource "aws_route_table" {
    defaults = { id = "rtb-0123456789abcdef0" }
  }
  mock_resource "aws_ec2_transit_gateway_vpc_attachment" {
    defaults = { transit_gateway_id = "tgw-0123456789abcdef0" }
  }
}

override_resource {
  target = aws_subnet.a
  values = { id = "subnet-0000000000000000a" }
}

override_resource {
  target = aws_subnet.b
  values = { id = "subnet-0000000000000000b" }
}

variables {
  details = { scope = "Test", purpose = "Same Run", environment = "test" }
}

run "plans_with_unknown_ids" {
  command = plan
  module {
    source = "./tests/fixtures/same_run"
  }
}

run "applies" {
  command = apply
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition = alltrue([
      output.metadata.vpc_attachment.vpc_id == "vpc-0123456789abcdef0",
      output.metadata.route["private"].route_table_id == "rtb-0123456789abcdef0",
      output.metadata.route["private"].transit_gateway_id == "tgw-0123456789abcdef0",
    ])
    error_message = "Unexpected result with same-run inputs."
  }
}
