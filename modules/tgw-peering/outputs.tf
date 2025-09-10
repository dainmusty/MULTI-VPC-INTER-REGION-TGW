output "peering_attachment_id" {
  value = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach.id
}

output "peering_accepter_id" {
  value = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_accept.id
}

