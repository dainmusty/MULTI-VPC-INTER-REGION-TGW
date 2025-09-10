# ----------------------------
# TGW Peering Attachment + Acceptance
# ----------------------------
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering_attach" {
  for_each = var.peerings
  provider = aws.requester

  transit_gateway_id      = each.value.requester_tgw_id
  peer_transit_gateway_id = each.value.accepter_tgw_id
  peer_region             = each.value.accepter_region

  tags = merge(
    var.tags,
    { Name = "tgw-peering-${each.key}" }
  )
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering_accept" {
  for_each = var.peerings
  provider = aws.accepter

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach[each.key].id

  tags = merge(
    var.tags,
    { Name = "tgw-peering-${each.key}-accepter" }
  )
}

# ----------------------------
# Routes in Requester TGW
# ----------------------------
resource "aws_ec2_transit_gateway_route" "requester_routes" {
  for_each = {
    for key, peering in var.peerings : "${key}-req" => {
      rt_id       = peering.requester_rt_id
      routes      = peering.requester_routes
      attach_id   = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach[key].id
    }
    if length(peering.requester_routes) > 0
  }
  provider = aws.requester

  transit_gateway_route_table_id = each.value.rt_id
  destination_cidr_block         = element(each.value.routes, 0)
  transit_gateway_attachment_id  = each.value.attach_id
}

# ----------------------------
# Routes in Accepter TGW
# ----------------------------
resource "aws_ec2_transit_gateway_route" "accepter_routes" {
  for_each = {
    for key, peering in var.peerings : "${key}-acc" => {
      rt_id       = peering.accepter_rt_id
      routes      = peering.accepter_routes
      attach_id   = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_accept[key].id
    }
    if length(peering.accepter_routes) > 0
  }
  provider = aws.accepter

  transit_gateway_route_table_id = each.value.rt_id
  destination_cidr_block         = element(each.value.routes, 0)
  transit_gateway_attachment_id  = each.value.attach_id
}
