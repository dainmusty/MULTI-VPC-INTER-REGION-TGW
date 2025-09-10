resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering_attach" {
  provider = aws.requester

  transit_gateway_id      = var.requester_tgw_id
  peer_transit_gateway_id = var.accepter_tgw_id
  peer_region             = var.accepter_region

  tags = merge(var.tags, {
    Name = "tgw-peering-${var.requester_region}-${var.accepter_region}"
  })
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering_accept" {
  provider = aws.accepter

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach.id

  tags = merge(var.tags, {
    Name = "tgw-peering-accept-${var.requester_region}-${var.accepter_region}"
  })
}
