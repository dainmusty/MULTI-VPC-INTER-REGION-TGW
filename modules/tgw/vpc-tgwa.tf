resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_tgw_attach" {
  for_each = var.attachments

  transit_gateway_id = aws_ec2_transit_gateway.multi_tgw.id
  vpc_id             = each.key
  subnet_ids         = each.value.subnet_ids

  tags = {
    Name = "${each.key}-tgw-attach"
  }
}
