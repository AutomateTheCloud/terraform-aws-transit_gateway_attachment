# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `vpc_attachment` - The attachment, with its `id` (the `transit_gateway_attachment_id` that transit gateway route tables refer to), `arn`, `transit_gateway_id`, `vpc_id`, `vpc_owner_id`, `subnet_ids`, each option as `enable` or `disable`, `transit_gateway_default_route_table_association` and `transit_gateway_default_route_table_propagation`, and its `tags`.
    - `route` - The routes, keyed like `routes`, each with its `route_table_id`, destination, `transit_gateway_id` and `state`, or `null` when there are none.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource.
    route          = local.output_resources.route
    vpc_attachment = local.output_resources.vpc_attachment
  }
}

locals {
  # Each resource's attributes are listed one by one, and the route map iterates over the
  # input keys, not over the resources. Referencing a whole resource, or iterating over
  # one, would also reference any attribute the provider deprecates later, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    # Keyed like var.routes. Left out: odb_network_arn, which is newer than the provider
    # floor.
    route = length(var.routes) == 0 ? null : {
      for k in keys(var.routes) : k => {
        carrier_gateway_id          = aws_route.this[k].carrier_gateway_id
        core_network_arn            = aws_route.this[k].core_network_arn
        destination_cidr_block      = aws_route.this[k].destination_cidr_block
        destination_ipv6_cidr_block = aws_route.this[k].destination_ipv6_cidr_block
        destination_prefix_list_id  = aws_route.this[k].destination_prefix_list_id
        egress_only_gateway_id      = aws_route.this[k].egress_only_gateway_id
        gateway_id                  = aws_route.this[k].gateway_id
        id                          = aws_route.this[k].id
        instance_id                 = aws_route.this[k].instance_id
        instance_owner_id           = aws_route.this[k].instance_owner_id
        local_gateway_id            = aws_route.this[k].local_gateway_id
        nat_gateway_id              = aws_route.this[k].nat_gateway_id
        network_interface_id        = aws_route.this[k].network_interface_id
        origin                      = aws_route.this[k].origin
        region                      = aws_route.this[k].region
        route_table_id              = aws_route.this[k].route_table_id
        state                       = aws_route.this[k].state
        transit_gateway_id          = aws_route.this[k].transit_gateway_id
        vpc_endpoint_id             = aws_route.this[k].vpc_endpoint_id
        vpc_peering_connection_id   = aws_route.this[k].vpc_peering_connection_id
      }
    }

    vpc_attachment = {
      appliance_mode_support                          = aws_ec2_transit_gateway_vpc_attachment.this.appliance_mode_support
      arn                                             = aws_ec2_transit_gateway_vpc_attachment.this.arn
      dns_support                                     = aws_ec2_transit_gateway_vpc_attachment.this.dns_support
      id                                              = aws_ec2_transit_gateway_vpc_attachment.this.id
      ipv6_support                                    = aws_ec2_transit_gateway_vpc_attachment.this.ipv6_support
      region                                          = aws_ec2_transit_gateway_vpc_attachment.this.region
      security_group_referencing_support              = aws_ec2_transit_gateway_vpc_attachment.this.security_group_referencing_support
      subnet_ids                                      = aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids
      tags                                            = aws_ec2_transit_gateway_vpc_attachment.this.tags
      tags_all                                        = aws_ec2_transit_gateway_vpc_attachment.this.tags_all
      transit_gateway_default_route_table_association = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_default_route_table_association
      transit_gateway_default_route_table_propagation = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_default_route_table_propagation
      transit_gateway_id                              = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_id
      vpc_id                                          = aws_ec2_transit_gateway_vpc_attachment.this.vpc_id
      vpc_owner_id                                    = aws_ec2_transit_gateway_vpc_attachment.this.vpc_owner_id
    }
  }
}
