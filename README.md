# AWS - Transit Gateway Attachment - Terraform Module
Terraform module to Attach Transit Gateways to VPCs (AutomateTheCloud model)

***

## Usage
```hcl
module "transit_gateway_attachment" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Infrastructure"
    purpose             = "Transit Gateway Attachment"
    purpose_abbr        = "tgw"
    environment         = "prd"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  vpc_id                       = "vpc-01234567891234567"
  transit_gateway_id           = "tgw-01234567891234567"

  subnet_ids                   = [ "subnet-a1234567891234567", "subnet-b1234567891234567", "subnet-c1234567891234567" ]
  subnet_to_attach_network_tag = "private"

  routes_to_populate           = [ "10.0.0.0/8", "172.16.0.0/16" ]

  enable_dns_support           = true
  enable_ipv6_support          = false
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `enable_dns_support` | Enable DNS Support | `bool` | `true` |
| `enable_ipv6_support` | Enable IPv6 Support | `bool` | `false` |
| `subnet_ids` | Subnet IDs | `list` | `[]` |
| `routes_to_populate` | Routes to populate from Transit Gateway | `list` | `[]` |
| `subnet_to_attach_network_tag` | Subnet to Attach: Network Tag | `string` | `private` |
| `transit_gateway_id` | Transit Gateway ID | `string` | |
| `vpc_id` | VPC ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `route_tables` | Route Tables updated |
| `subnets` | Subnets updated |
| `transit_gateway.vpc_attachment` | Transit Gateway VPC Attachement |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
