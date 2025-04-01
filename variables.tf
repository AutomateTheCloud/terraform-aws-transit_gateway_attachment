variable "enable_dns_support" {
  description = "Enable DNS Support"
  type        = bool
  default     = true
}

variable "enable_ipv6_support" {
  description = "Enable IPv6 Support"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs whose routes to populate from Transit Gateway"
  type        = list(any)
  default     = []
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "Subnet IDs not Specified."
  }
}

variable "routes_to_populate" {
  description = "Routes to populate from Transit Gateway"
  type        = list(any)
  default     = []
  validation {
    condition     = length(var.routes_to_populate) > 0
    error_message = "Routes to Populate not Specified."
  }
}

variable "subnet_to_attach_network_tag" {
  description = "Subnet to Attach: Network Tag"
  type        = string
  default     = "private"
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC: ID"
  type        = string
  default     = ""
}
