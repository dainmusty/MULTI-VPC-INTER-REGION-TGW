# Named TGW route tables (e.g., prod/dev)
resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  for_each           = toset(var.route_table_names)
  transit_gateway_id = aws_ec2_transit_gateway.multi_tgw.id
  tags               = merge(var.tags, { Name = "${var.project}-${var.tgw_name}-rt-${each.key}" })
}

# Associate each attachment to chosen TGW RT (if specified)
# Associate attachments with route tables
resource "aws_ec2_transit_gateway_route_table_association" "tgw_rt_assoc" {
  for_each = var.attachments

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_tgw_attach[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt[each.value.associate_with].id
}

# Propagate attachments
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_rt_prop" {
  for_each = var.attachments

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_tgw_attach[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt[each.value.propagate_to].id
}

