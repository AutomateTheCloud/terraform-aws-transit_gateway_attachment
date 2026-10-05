# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# One VPC attached to a transit gateway, with a route that sends 10.0.0.0/8 from the
# VPC's private route table to the transit gateway. The transit gateway and the VPC are
# built here from plain resources so the example stands alone.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  details = {
    scope       = "Example"
    purpose     = "Basic Transit Gateway Attachment"
    environment = "Development"
  }
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# A transit gateway with AWS's default settings: every attachment is associated with its
# default route table and adds its routes there, so attached VPCs can reach each other.
resource "aws_ec2_transit_gateway" "this" {
  description = "example-basic"
  tags        = { Name = "example-basic" }
}

resource "aws_vpc" "this" {
  cidr_block = "10.50.0.0/16"
  tags       = { Name = "example-basic-transit-gateway-attachment" }
}

# One private subnet in each of two Availability Zones. The attachment places a network
# interface of the transit gateway in each.
resource "aws_subnet" "private" {
  for_each = toset(local.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, index(local.availability_zones, each.key))
  availability_zone = each.key
  tags              = { Name = "example-basic-private-${each.key}" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "example-basic-private" }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

module "transit_gateway_attachment" {
  source = "../../"

  details = local.details

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [for s in aws_subnet.private : s.id]

  # Traffic from the private subnets to other networks in 10.0.0.0/8 goes to the transit
  # gateway. Traffic within this VPC (10.50.0.0/16) stays local: the more specific route wins.
  routes = {
    private = { route_table_id = aws_route_table.private.id, destination_cidr_block = "10.0.0.0/8" }
  }
}

output "transit_gateway_attachment_id" {
  description = "The attachment's ID, which transit gateway route tables refer to"
  value       = module.transit_gateway_attachment.metadata.vpc_attachment.id
}
