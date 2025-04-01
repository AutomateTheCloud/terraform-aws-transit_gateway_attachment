resource "aws_route" "this" {
  count                  = (length(var.subnet_ids) * length(var.routes_to_populate))
  route_table_id         = data.aws_route_table.this[floor(count.index / length(var.routes_to_populate))].route_table_id
  destination_cidr_block = var.routes_to_populate[count.index % length(var.routes_to_populate)]
  transit_gateway_id     = data.aws_ec2_transit_gateway.this.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this
  ]
  provider = aws.this
}
