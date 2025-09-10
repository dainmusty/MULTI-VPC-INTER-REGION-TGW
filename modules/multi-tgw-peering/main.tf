resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering_attach" {
  for_each = var.peerings

  provider = aws.requester

  transit_gateway_id      = each.value.requester_tgw_id
  peer_transit_gateway_id = each.value.accepter_tgw_id
  peer_region             = each.value.accepter_region

  tags = merge(
    var.tags,
    {
      Name = "tgw-peering-${each.key}"
    }
  )
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering_accept" {
  for_each = var.peerings

  provider = aws.accepter

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach[each.key].id

  tags = merge(
    var.tags,
    {
      Name = "tgw-peering-${each.key}-accepter"
    }
  )
}
