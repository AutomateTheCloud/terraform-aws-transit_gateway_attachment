# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A VPC attached to a transit gateway that has its own route table instead of the default
# one. The attachment has dedicated /28 subnets, security group referencing is turned on,
# and two route tables send other networks' traffic to the transit gateway: one IPv4
# range, and the ranges in a managed prefix list.

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
    scope           = "Example"
    purpose         = "Complete Transit Gateway Attachment"
    environment     = "Development"
    additional_tags = { CostCenter = "1234" }
  }
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# The transit gateway does not associate attachments with a default route table, or add
# their routes to one: each attachment is placed explicitly, below.
resource "aws_ec2_transit_gateway" "this" {
  description                        = "example-complete"
  default_route_table_association    = "disable"
  default_route_table_propagation    = "disable"
  security_group_referencing_support = "enable"
  tags                               = { Name = "example-complete" }
}

resource "aws_ec2_transit_gateway_route_table" "shared" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "example-complete-shared" }
}

resource "aws_vpc" "this" {
  cidr_block = "10.60.0.0/16"
  tags       = { Name = "example-complete-transit-gateway-attachment" }
}

# Small subnets used only by the attachment, one in each Availability Zone, and larger
# application subnets whose route tables send traffic to the transit gateway.
resource "aws_subnet" "attachment" {
  for_each = toset(local.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 12, index(local.availability_zones, each.key))
  availability_zone = each.key
  tags              = { Name = "example-complete-attachment-${each.key}" }
}

resource "aws_subnet" "application" {
  for_each = toset(local.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 10 + index(local.availability_zones, each.key))
  availability_zone = each.key
  tags              = { Name = "example-complete-application-${each.key}" }
}

resource "aws_route_table" "application" {
  for_each = toset(local.availability_zones)

  vpc_id = aws_vpc.this.id
  tags   = { Name = "example-complete-application-${each.key}" }
}

resource "aws_route_table_association" "application" {
  for_each = toset(local.availability_zones)

  subnet_id      = aws_subnet.application[each.key].id
  route_table_id = aws_route_table.application[each.key].id
}

# The networks of a partner reached through the transit gateway, kept in one list.
resource "aws_ec2_managed_prefix_list" "partner" {
  name           = "example-complete-partner"
  address_family = "IPv4"
  max_entries    = 5

  entry {
    cidr        = "192.168.10.0/24"
    description = "Partner office"
  }
  entry {
    cidr        = "192.168.20.0/24"
    description = "Partner data center"
  }
}

module "transit_gateway_attachment" {
  source = "../../"

  details = local.details

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [for s in aws_subnet.attachment : s.id]

  attachment = {
    security_group_referencing_support = true
    default_route_table_association    = false
    default_route_table_propagation    = false
    name                               = "example-complete"
  }

  routes = merge(
    {
      for zone in local.availability_zones : "internal_${zone}" => {
        route_table_id         = aws_route_table.application[zone].id
        destination_cidr_block = "10.0.0.0/8"
      }
    },
    {
      for zone in local.availability_zones : "partner_${zone}" => {
        route_table_id             = aws_route_table.application[zone].id
        destination_prefix_list_id = aws_ec2_managed_prefix_list.partner.id
      }
    },
  )
}

# Traffic from the VPC is routed by the shared route table, and the VPC's range is added
# to it, so other attachments associated with that table can reach the VPC.
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  transit_gateway_attachment_id  = module.transit_gateway_attachment.metadata.vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  transit_gateway_attachment_id  = module.transit_gateway_attachment.metadata.vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

output "transit_gateway_attachment_id" {
  description = "The attachment's ID"
  value       = module.transit_gateway_attachment.metadata.vpc_attachment.id
}

output "routes" {
  description = "Each route the module added, with its route table and destination"
  value = {
    for k, r in module.transit_gateway_attachment.metadata.route : k => {
      route_table_id = r.route_table_id
      destination    = coalesce(r.destination_cidr_block, r.destination_prefix_list_id)
    }
  }
}
