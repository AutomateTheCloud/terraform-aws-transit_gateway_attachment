# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details            = { scope = "Test", purpose = "Defaults", environment = "test" }
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
}

# With only the required inputs: the attachment in the listed subnets, with DNS support
# on as in AWS and every other option off, and no routes, so nothing in the VPC uses the attachment until listed.
run "defaults" {
  command = apply

  assert {
    condition = alltrue([
      aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_id == "tgw-0123456789abcdef0",
      aws_ec2_transit_gateway_vpc_attachment.this.vpc_id == "vpc-0123456789abcdef0",
      aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids == toset(["subnet-0000000000000000a", "subnet-0000000000000000b"]),
      aws_ec2_transit_gateway_vpc_attachment.this.dns_support == "enable",
      aws_ec2_transit_gateway_vpc_attachment.this.ipv6_support == "disable",
      aws_ec2_transit_gateway_vpc_attachment.this.appliance_mode_support == "disable",
      aws_ec2_transit_gateway_vpc_attachment.this.security_group_referencing_support == "disable",
      length(aws_route.this) == 0,
    ])
    error_message = "Unexpected defaults."
  }
  assert {
    condition = alltrue([
      output.metadata.vpc_attachment.id == aws_ec2_transit_gateway_vpc_attachment.this.id,
      output.metadata.vpc_attachment.vpc_id == "vpc-0123456789abcdef0",
      output.metadata.route == null,
      output.metadata.aws.region.name == "us-east-1",
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
    ])
    error_message = "Unexpected metadata output."
  }
}

run "tags" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Defaults", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = aws_ec2_transit_gateway_vpc_attachment.this.tags == tomap({
      Scope       = "Test"
      Purpose     = "Defaults"
      Environment = "test"
      CostCenter  = "1234"
      Name        = "test-defaults-test-use1"
    })
    error_message = "Unexpected attachment tags."
  }
}

# An empty abbreviation override counts as not set.
run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "Transit Gateway", purpose_abbr = "", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "transit_gateway",
      output.metadata.details.purpose.machine == "transitgateway",
      aws_ec2_transit_gateway_vpc_attachment.this.tags["Name"] == "atc-org-transit_gateway-production-use1",
    ])
    error_message = "Unexpected abbreviations."
  }
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}
