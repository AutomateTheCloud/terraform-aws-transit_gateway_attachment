data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}

data "aws_ec2_transit_gateway" "this" {
  id       = var.transit_gateway_id
  provider = aws.this
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Network"
    values = [var.subnet_to_attach_network_tag]
  }
  provider = aws.this
}

data "aws_route_table" "this" {
  count     = (length(var.subnet_ids))
  vpc_id    = data.aws_vpc.this.id
  subnet_id = var.subnet_ids[count.index]
  provider  = aws.this
}
