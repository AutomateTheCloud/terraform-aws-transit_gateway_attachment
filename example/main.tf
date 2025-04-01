terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: Transit Gateway Attachment
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

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.transit_gateway_attachment.metadata
}
