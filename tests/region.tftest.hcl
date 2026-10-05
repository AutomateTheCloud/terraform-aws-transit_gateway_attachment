# Copyright 2025 Automate the Cloud Inc.
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
  details            = { scope = "Test", purpose = "Region", environment = "test" }
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
  routes             = { private = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" } }
}

# The module uses the default aws provider: no providers block is needed.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables { region = "us-west-2" }
  assert {
    condition = alltrue([
      aws_ec2_transit_gateway_vpc_attachment.this.region == "us-west-2",
      aws_route.this["private"].region == "us-west-2",
      output.metadata.vpc_attachment.region == "us-west-2",
      output.metadata.route["private"].region == "us-west-2",
      output.metadata.aws.region.name == "us-west-2",
      output.metadata.aws.region.abbr == "usw2",
      aws_ec2_transit_gateway_vpc_attachment.this.tags["Name"] == "test-region-test-usw2",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Regression: the old hard-coded Region table failed the plan in any Region missing
# from it, such as mx-central-1 (Mexico).
run "region_abbreviation_not_in_old_table" {
  command = plan
  variables { region = "mx-central-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1" && aws_ec2_transit_gateway_vpc_attachment.this.tags["Name"] == "test-region-test-mxc1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables { region = "ap-southeast-5" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse5"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
