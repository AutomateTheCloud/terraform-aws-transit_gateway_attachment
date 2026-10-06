# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}

variables {
  details            = { scope = "Test", purpose = "Validation", environment = "test" }
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0123456789abcdef0"]
}

run "transit_gateway_id_invalid" {
  command = plan
  variables { transit_gateway_id = "" }
  expect_failures = [var.transit_gateway_id]
}

run "transit_gateway_id_wrong_type" {
  command = plan
  variables { transit_gateway_id = "tgw-attach-0123456789abcdef0" }
  expect_failures = [var.transit_gateway_id]
}

run "vpc_id_invalid" {
  command = plan
  variables { vpc_id = "" }
  expect_failures = [var.vpc_id]
}

run "short_ids_accepted" {
  command = plan
  variables {
    transit_gateway_id = "tgw-01234567"
    vpc_id             = "vpc-01234567"
    subnet_ids         = ["subnet-01234567"]
  }
}

run "subnet_ids_empty" {
  command = plan
  variables { subnet_ids = [] }
  expect_failures = [var.subnet_ids]
}

run "subnet_ids_invalid" {
  command = plan
  variables { subnet_ids = ["subnet-0123456789abcdef0", "rtb-0123456789abcdef0"] }
  expect_failures = [var.subnet_ids]
}

run "subnet_ids_duplicate" {
  command = plan
  variables { subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef0"] }
  expect_failures = [var.subnet_ids]
}

run "name_empty" {
  command = plan
  variables { attachment = { name = " " } }
  expect_failures = [var.attachment]
}

run "name_too_long" {
  command = plan
  variables { attachment = { name = join("", [for i in range(257) : "n"]) } }
  expect_failures = [var.attachment]
}

run "route_table_id_invalid" {
  command = plan
  variables { routes = { r = { route_table_id = "subnet-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" } } }
  expect_failures = [var.routes]
}

run "route_without_destination" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0" } } }
  expect_failures = [var.routes]
}

run "route_with_two_destinations" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8", destination_prefix_list_id = "pl-0123456789abcdef0" } } }
  expect_failures = [var.routes]
}

run "destination_not_cidr" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0" } } }
  expect_failures = [var.routes]
}

run "destination_ipv6_in_ipv4_field" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "2600:1f18:1234:5600::/56" } } }
  expect_failures = [var.routes]
}

run "destination_host_bits" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.20.1.0/16" } } }
  expect_failures = [var.routes]
}

run "destination_ipv6_invalid" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_ipv6_cidr_block = "10.0.0.0/8" } } }
  expect_failures = [var.routes]
}

run "destination_ipv6_host_bits" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_ipv6_cidr_block = "2600:1f18:1234:5601::/56" } } }
  expect_failures = [var.routes]
}

run "destination_ipv6_uppercase_accepted" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_ipv6_cidr_block = "2600:1F18:1234:5600::/56" } } }
}

run "prefix_list_invalid" {
  command = plan
  variables { routes = { r = { route_table_id = "rtb-0123456789abcdef0", destination_prefix_list_id = "com.amazonaws.us-east-1.s3" } } }
  expect_failures = [var.routes]
}

# Regression: two subnets sharing a route table got the same route twice, and the second
# failed at apply. Listing a route table twice for one destination now fails at plan time.
run "duplicate_route" {
  command = plan
  variables {
    routes = {
      r1 = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" }
      r2 = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" }
    }
  }
  expect_failures = [var.routes]
}

run "same_table_other_destination_accepted" {
  command = plan
  variables {
    routes = {
      r1 = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" }
      r2 = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "172.16.0.0/12" }
    }
  }
}
