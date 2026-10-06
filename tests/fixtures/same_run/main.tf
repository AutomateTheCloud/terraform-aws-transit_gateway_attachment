# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A transit gateway, a VPC, its subnets and a route table created in the same run as the
# module. Their IDs are unknown at plan time, so the module must not decide count or
# for_each from them.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "details" {
  type = object({ scope = string, purpose = string, environment = string })
}

resource "aws_ec2_transit_gateway" "this" {}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.0.0/28"
}

resource "aws_subnet" "b" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.0.16/28"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

module "transit_gateway_attachment" {
  source = "../../.."

  details            = var.details
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [aws_subnet.a.id, aws_subnet.b.id]
  routes = {
    private = { route_table_id = aws_route_table.private.id, destination_cidr_block = "10.0.0.0/8" }
  }
}

output "metadata" {
  value = module.transit_gateway_attachment.metadata
}
