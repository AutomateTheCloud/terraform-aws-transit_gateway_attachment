resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = data.aws_ec2_transit_gateway.this.id
  vpc_id             = data.aws_vpc.this.id
  subnet_ids         = data.aws_subnets.this.ids
  dns_support        = (var.enable_dns_support ? "enable" : "disable")
  ipv6_support       = (var.enable_ipv6_support ? "enable" : "disable")

  tags = merge(
    local.tags,
    tomap({
      "Name" = "${data.aws_ec2_transit_gateway.this.description} - ${data.aws_vpc.this.id} (${try(data.aws_vpc.this.tags["Name"], "")})"
    })
  )

  provider = aws.this
}
