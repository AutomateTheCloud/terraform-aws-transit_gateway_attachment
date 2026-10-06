# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "attachment" {
  description = <<-EOT
    Settings of the attachment. Every setting has a default, so this input can be left out.

    - `dns_support` - (Optional) Whether DNS names of instances in other VPCs and networks attached to the transit gateway resolve to private IP addresses from this VPC. Defaults to `true`, as in AWS. It works only when the transit gateway also has DNS support turned on.
    - `ipv6_support` - (Optional) Whether IPv6 traffic passes through the attachment. Defaults to `false`. Each subnet in `subnet_ids` then needs an IPv6 range.
    - `appliance_mode_support` - (Optional) Whether traffic between two networks stays in the same Availability Zone of this VPC in both directions. Defaults to `false`. Turn it on only when the VPC holds a stateful network appliance, such as a firewall, that must see both directions of each connection.
    - `security_group_referencing_support` - (Optional) Whether security groups in other VPCs attached to the transit gateway can refer to security groups in this VPC, and the other way round. Defaults to `false`. It works only when the transit gateway also has security group referencing turned on, and only within one Region.
    - `default_route_table_association` - (Optional) Whether to associate the attachment with the transit gateway's default route table: the table that decides where traffic from this VPC goes. Defaults to `null`: the transit gateway's own setting decides. Leave it `null` for a transit gateway shared from another account through AWS Resource Access Manager (RAM); it cannot be set there.
    - `default_route_table_propagation` - (Optional) Whether to add this VPC's address ranges to the transit gateway's default route table, so traffic from other attachments can reach it. Defaults to `null`: the transit gateway's own setting decides. Leave it `null` for a transit gateway shared through RAM.
    - `name` - (Optional) The attachment's `Name` tag. Defaults to `<scope>-<purpose>-<environment>-<region>`, from the `details` abbreviations, such as `automate_the_cloud-web_site-production-use1`.

    Each of these is changed in place, without replacing the attachment.
  EOT
  type = object({
    dns_support                        = optional(bool, true)
    ipv6_support                       = optional(bool, false)
    appliance_mode_support             = optional(bool, false)
    security_group_referencing_support = optional(bool, false)
    default_route_table_association    = optional(bool)
    default_route_table_propagation    = optional(bool)
    name                               = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.attachment.name == null || try(trimspace(var.attachment.name) != "" && length(var.attachment.name) <= 256, false)
    error_message = "attachment.name must be 1 to 256 characters, the limit for a tag value. Leave it out for the default name."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the attachment and routes in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The transit gateway, the VPC, its subnets and the route tables must all be in this Region.
  EOT
  type        = string
  default     = null
}

variable "routes" {
  description = <<-EOT
    Routes that send traffic from a route table in the VPC to the transit gateway, as a map of names you choose to settings, such as `{ private_a = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" } }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: until a route table sends traffic to the transit gateway, nothing in the VPC uses the attachment.

    - `route_table_id` - (Required) The route table to add the route to, such as `rtb-0123456789abcdef0`. List the route table of each subnet whose traffic should reach the transit gateway; a subnet with no route table of its own uses the VPC's main route table.
    - `destination_cidr_block` - (Optional) An IPv4 range to send to the transit gateway, in CIDR notation, such as `10.0.0.0/8`.
    - `destination_ipv6_cidr_block` - (Optional) An IPv6 range to send to the transit gateway, in CIDR notation, such as `2600:1f18:1234:5600::/56`. The attachment needs `ipv6_support` for IPv6 traffic to pass.
    - `destination_prefix_list_id` - (Optional) A managed prefix list whose ranges to send to the transit gateway, such as `pl-0123456789abcdef0`.

    Set exactly one of the three destinations. Each route table can have only one route for each destination.
  EOT
  type = map(object({
    route_table_id              = string
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for v in values(var.routes) : can(regex("^rtb-[0-9a-f]{8}([0-9a-f]{9})?$", v.route_table_id))])
    error_message = "Each routes route_table_id must be a route table ID, such as rtb-0123456789abcdef0."
  }

  validation {
    condition     = alltrue([for v in values(var.routes) : length([for d in [v.destination_cidr_block, v.destination_ipv6_cidr_block, v.destination_prefix_list_id] : d if d != null]) == 1])
    error_message = "Each route must set exactly one of destination_cidr_block, destination_ipv6_cidr_block and destination_prefix_list_id."
  }

  validation {
    condition = alltrue([for v in values(var.routes) : v.destination_cidr_block == null || try(
      can(cidrnetmask(v.destination_cidr_block)) && cidrhost(v.destination_cidr_block, 0) == split("/", v.destination_cidr_block)[0],
      false
    )])
    error_message = "Each routes destination_cidr_block must be an IPv4 network in CIDR notation, such as 10.0.0.0/8, with no host bits set (10.20.0.0/16, not 10.20.1.0/16). AWS would save 10.20.0.0/16 instead, which no longer matches the configuration."
  }

  validation {
    condition = alltrue([for v in values(var.routes) : v.destination_ipv6_cidr_block == null || try(
      strcontains(v.destination_ipv6_cidr_block, ":") && cidrhost(v.destination_ipv6_cidr_block, 0) == cidrhost("${split("/", v.destination_ipv6_cidr_block)[0]}/128", 0),
      false
    )])
    error_message = "Each routes destination_ipv6_cidr_block must be an IPv6 network in CIDR notation, such as 2600:1f18:1234:5600::/56, with no host bits set."
  }

  validation {
    condition     = alltrue([for v in values(var.routes) : v.destination_prefix_list_id == null || can(regex("^pl-[0-9a-f]{8}([0-9a-f]{9})?$", v.destination_prefix_list_id))])
    error_message = "Each routes destination_prefix_list_id must be a prefix list ID, such as pl-0123456789abcdef0."
  }

  validation {
    condition     = length(distinct([for v in values(var.routes) : "${v.route_table_id} ${coalesce(v.destination_cidr_block, v.destination_ipv6_cidr_block, v.destination_prefix_list_id, "none")}"])) == length(var.routes)
    error_message = "routes lists the same route_table_id and destination more than once. A route table can hold only one route for each destination."
  }
}

variable "subnet_ids" {
  description = <<-EOT
    The subnets of the VPC to attach to the transit gateway, such as `["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]`. AWS places a network interface of the transit gateway in each one. List one subnet in each Availability Zone whose resources should reach the transit gateway; AWS accepts at most one subnet per zone. A small subnet used only for the attachment, such as a `/28`, keeps its addresses apart from your instances.

    Subnets can be added or removed later without replacing the attachment.
  EOT
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must list at least one subnet."
  }

  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^subnet-[0-9a-f]{8}([0-9a-f]{9})?$", s))])
    error_message = "Each subnet_ids entry must be a subnet ID, such as subnet-0123456789abcdef0."
  }

  validation {
    condition     = length(distinct(var.subnet_ids)) == length(var.subnet_ids)
    error_message = "subnet_ids lists the same subnet more than once."
  }
}

variable "transit_gateway_id" {
  description = <<-EOT
    The transit gateway to attach the VPC to, such as `tgw-0123456789abcdef0`. It can be in this account or shared with it from another account through AWS Resource Access Manager (RAM). Changing it replaces the attachment.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^tgw-[0-9a-f]{8}([0-9a-f]{9})?$", var.transit_gateway_id))
    error_message = "transit_gateway_id must be a transit gateway ID, such as tgw-0123456789abcdef0."
  }
}

variable "vpc_id" {
  description = <<-EOT
    The VPC to attach, such as `vpc-0123456789abcdef0`. Changing it replaces the attachment.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8}([0-9a-f]{9})?$", var.vpc_id))
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}
