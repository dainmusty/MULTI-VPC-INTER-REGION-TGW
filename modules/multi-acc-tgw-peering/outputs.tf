output "peering_attachment_ids" {
  value = { for k, v in aws_ec2_transit_gateway_peering_attachment.tgw_peering_attach : k => v.id }
}

output "peering_accepter_ids" {
  value = { for k, v in aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_accept : k => v.id }
}