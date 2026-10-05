# Terraform module for AWS Transit Gateway VPC attachments

Attaches an Amazon Virtual Private Cloud (VPC) to an AWS Transit Gateway, and adds the routes that send traffic from the VPC's route tables to the transit gateway. A transit gateway is a regional router: each VPC, VPN connection or Direct Connect gateway attached to it can reach the others, as its route tables allow.

You list the subnets to attach and the routes to add, by ID. The module looks nothing up, so it works with a VPC and a transit gateway from any source, including ones created in the same configuration.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Attachment | In the subnets you list, at most one per Availability Zone | `transit_gateway_id`, `vpc_id`, `subnet_ids` (required) |
| DNS support | On, as in AWS: names in other attached VPCs resolve to private addresses | `attachment.dns_support` |
| IPv6, appliance mode, security group referencing | Off | `attachment.ipv6_support`, `attachment.appliance_mode_support`, `attachment.security_group_referencing_support` |
| Transit gateway route table | The transit gateway's own default settings decide | `attachment.default_route_table_association`, `attachment.default_route_table_propagation` |
| `Name` tag | `<scope>-<purpose>-<environment>-<region>` | `attachment.name` |
| Routes in the VPC | None: nothing in the VPC uses the attachment until a route table sends traffic to it | `routes` |

## Usage

```hcl
module "transit_gateway_attachment" {
  source  = "AutomateTheCloud/transit_gateway_attachment/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = aws_vpc.this.id

  # One subnet in each Availability Zone the VPC uses.
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # The private subnets send traffic for the rest of the company network to the transit gateway.
  routes = {
    private_a = { route_table_id = aws_route_table.private_a.id, destination_cidr_block = "10.0.0.0/8" }
    private_b = { route_table_id = aws_route_table.private_b.id, destination_cidr_block = "10.0.0.0/8" }
  }
}
```

`details`, `transit_gateway_id`, `vpc_id` and `subnet_ids` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags, and the `Name` tag, here `automate_the_cloud-web_site-production-use1`.

The module uses your default `aws` provider and creates everything in that provider's Region. To attach a VPC somewhere else without configuring another provider, set `region`; the transit gateway, the VPC and its route tables must be in that Region too:

```hcl
module "transit_gateway_attachment_us_west_2" {
  source  = "AutomateTheCloud/transit_gateway_attachment/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Web Site", environment = "Production" }

  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0123456789abcdef0"]
}
```

Because `region` is an ordinary input, one module block can attach VPCs in each of several Regions with `for_each`.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the attachment belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a transit gateway attachment in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the attachment, the VPC it connects, the transit gateway and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_transit_gateway_attachment" {
  source  = "AutomateTheCloud/transit_gateway_attachment/aws"
  version = "~> 1.0"

  details            = local.details
  transit_gateway_id = "tgw-0123456789abcdef0"
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_transit_gateway_attachment.metadata.vpc_attachment.id` for the attachment's ID, or `module.site_transit_gateway_attachment.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. Transit gateway attachments are billed by the hour, so destroy an example when you are done with it.

- [Basic attachment](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/tree/main/examples/basic): a VPC attached to a new transit gateway in two Availability Zones, with a route for `10.0.0.0/8`.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/tree/main/examples/complete): dedicated attachment subnets, security group referencing, routes to an IPv4 range and to a managed prefix list, and the attachment placed in a transit gateway route table of its own instead of the default one.

## Things to know

### Subnets

The attachment places a network interface of the transit gateway in each subnet you list. AWS accepts at most one subnet per Availability Zone (`DuplicateSubnetsInSameZone`), and one attachment for each VPC and transit gateway pair (`DuplicateTransitGatewayAttachment`). According to the [AWS documentation](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpc-attachments.html), resources in a zone with no attachment subnet cannot reach the transit gateway, so list a subnet in every zone the VPC uses. Many networks give the attachment small subnets of its own, such as a `/28` in each zone, so its addresses stay apart from the instances' and its subnets can have their own network ACLs. Subnets can be added or removed later; the attachment is changed in place, which took about four minutes in our tests.

### Routes in the VPC

Each route names its route table and one destination: an IPv4 range, an IPv6 range, or a managed prefix list. The module never looks up which subnet uses which route table, so a route table created in the same configuration can be used. A subnet with no route table of its own uses the VPC's main route table; list the main route table to reach it. Each route is created after the attachment, since it takes the transit gateway's ID from the attachment.

A route table can hold only one route for each destination. The plan fails if `routes` lists the same route table and destination twice, and the apply fails if the route table already has a route for that destination from somewhere else.

### Transit gateway route tables

The routes above decide which traffic leaves the VPC for the transit gateway. Where it goes from there is decided by the transit gateway's own route tables. Each attachment is associated with one of them, which routes the traffic that arrives from the VPC, and can add (propagate) the VPC's address ranges to any number of them, so other attachments can reach it.

By default, `attachment.default_route_table_association` and `attachment.default_route_table_propagation` are `null`, and the transit gateway's own settings decide: a transit gateway created with AWS's defaults associates every attachment with its default route table and propagates to it, so attached VPCs can reach each other. To place the attachment in another route table, set both to `false` and create an `aws_ec2_transit_gateway_route_table_association` and `aws_ec2_transit_gateway_route_table_propagation` with `metadata.vpc_attachment.id`, as the [complete example](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/tree/main/examples/complete) does. An attachment can be associated with only one route table at a time.

### A transit gateway in another account

A transit gateway shared with your account through AWS Resource Access Manager (RAM) is attached the same way, by its ID, once the share is accepted. Leave `attachment.default_route_table_association` and `attachment.default_route_table_propagation` at `null`: the [AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) says they cannot be set on an attachment to a shared transit gateway. Unless the transit gateway accepts shared attachments automatically, its owner must accept the attachment before traffic can flow; see [transit gateway attachments to a VPC](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpc-attachments.html) in the AWS documentation. The module does not create anything in the transit gateway's account. This case has not been tested with two accounts.

### Options that need the transit gateway too

According to the [AWS documentation](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpc-attachments.html), DNS support and security group referencing work only when the transit gateway also has them turned on, security group referencing works only between VPCs in the same Region, and IPv6 support needs an IPv6 range on each attached subnet.

### Changing the attachment

Changing `transit_gateway_id` or `vpc_id` replaces the attachment. Terraform deletes the old attachment before it creates the new one, so traffic stops until the new attachment is available, a few minutes later; the routes are then pointed at the new transit gateway in place. Associations and propagations you created for the old attachment are replaced too. Changing `subnet_ids`, an `attachment` option, or `details` changes the attachment in place. Removing an entry from `routes` removes only that route.

### Not covered

The module creates the attachment and the routes in the VPC. It does not create the transit gateway, its route tables, associations or propagations, or an accepter in the transit gateway owner's account.

### Cost

AWS bills each transit gateway attachment by the hour while it exists, and for each gigabyte of data sent to the transit gateway. See [AWS Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/).

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: The subnets of the VPC to attach to the transit gateway, such as `["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]`. AWS places a network interface of the transit gateway in each one. List one subnet in each Availability Zone whose resources should reach the transit gateway; AWS accepts at most one subnet per zone. A small subnet used only for the attachment, such as a `/28`, keeps its addresses apart from your instances.

Subnets can be added or removed later without replacing the attachment.

Type: `list(string)`

#### <a name="input_transit_gateway_id"></a> [transit_gateway_id](#input_transit_gateway_id)

Description: The transit gateway to attach the VPC to, such as `tgw-0123456789abcdef0`. It can be in this account or shared with it from another account through AWS Resource Access Manager (RAM). Changing it replaces the attachment.

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: The VPC to attach, such as `vpc-0123456789abcdef0`. Changing it replaces the attachment.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_attachment"></a> [attachment](#input_attachment)

Description: Settings of the attachment. Every setting has a default, so this input can be left out.

- `dns_support` - (Optional) Whether DNS names of instances in other VPCs and networks attached to the transit gateway resolve to private IP addresses from this VPC. Defaults to `true`, as in AWS. It works only when the transit gateway also has DNS support turned on.
- `ipv6_support` - (Optional) Whether IPv6 traffic passes through the attachment. Defaults to `false`. Each subnet in `subnet_ids` then needs an IPv6 range.
- `appliance_mode_support` - (Optional) Whether traffic between two networks stays in the same Availability Zone of this VPC in both directions. Defaults to `false`. Turn it on only when the VPC holds a stateful network appliance, such as a firewall, that must see both directions of each connection.
- `security_group_referencing_support` - (Optional) Whether security groups in other VPCs attached to the transit gateway can refer to security groups in this VPC, and the other way round. Defaults to `false`. It works only when the transit gateway also has security group referencing turned on, and only within one Region.
- `default_route_table_association` - (Optional) Whether to associate the attachment with the transit gateway's default route table: the table that decides where traffic from this VPC goes. Defaults to `null`: the transit gateway's own setting decides. Leave it `null` for a transit gateway shared from another account through AWS Resource Access Manager (RAM); it cannot be set there.
- `default_route_table_propagation` - (Optional) Whether to add this VPC's address ranges to the transit gateway's default route table, so traffic from other attachments can reach it. Defaults to `null`: the transit gateway's own setting decides. Leave it `null` for a transit gateway shared through RAM.
- `name` - (Optional) The attachment's `Name` tag. Defaults to `<scope>-<purpose>-<environment>-<region>`, from the `details` abbreviations, such as `automate_the_cloud-web_site-production-use1`.

Each of these is changed in place, without replacing the attachment.

Type:

```hcl
object({
    dns_support                        = optional(bool, true)
    ipv6_support                       = optional(bool, false)
    appliance_mode_support             = optional(bool, false)
    security_group_referencing_support = optional(bool, false)
    default_route_table_association    = optional(bool)
    default_route_table_propagation    = optional(bool)
    name                               = optional(string)
  })
```

Default: `{}`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the attachment and routes in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The transit gateway, the VPC, its subnets and the route tables must all be in this Region.

Type: `string`

Default: `null`

#### <a name="input_routes"></a> [routes](#input_routes)

Description: Routes that send traffic from a route table in the VPC to the transit gateway, as a map of names you choose to settings, such as `{ private_a = { route_table_id = "rtb-0123456789abcdef0", destination_cidr_block = "10.0.0.0/8" } }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: until a route table sends traffic to the transit gateway, nothing in the VPC uses the attachment.

- `route_table_id` - (Required) The route table to add the route to, such as `rtb-0123456789abcdef0`. List the route table of each subnet whose traffic should reach the transit gateway; a subnet with no route table of its own uses the VPC's main route table.
- `destination_cidr_block` - (Optional) An IPv4 range to send to the transit gateway, in CIDR notation, such as `10.0.0.0/8`.
- `destination_ipv6_cidr_block` - (Optional) An IPv6 range to send to the transit gateway, in CIDR notation, such as `2600:1f18:1234:5600::/56`. The attachment needs `ipv6_support` for IPv6 traffic to pass.
- `destination_prefix_list_id` - (Optional) A managed prefix list whose ranges to send to the transit gateway, such as `pl-0123456789abcdef0`.

Set exactly one of the three destinations. Each route table can have only one route for each destination.

Type:

```hcl
map(object({
    route_table_id              = string
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
  }))
```

Default: `{}`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `vpc_attachment` - The attachment, with its `id` (the `transit_gateway_attachment_id` that transit gateway route tables refer to), `arn`, `transit_gateway_id`, `vpc_id`, `vpc_owner_id`, `subnet_ids`, each option as `enable` or `disable`, `transit_gateway_default_route_table_association` and `transit_gateway_default_route_table_propagation`, and its `tags`.
- `route` - The routes, keyed like `routes`, each with its `route_table_id`, destination, `transit_gateway_id` and `state`, or `null` when there are none.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
