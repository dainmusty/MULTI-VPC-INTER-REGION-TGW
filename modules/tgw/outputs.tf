output "tgw_id" {
  value = aws_ec2_transit_gateway.multi_tgw.id
}

output "tgw_rt_ids" {
  value = { for k, v in aws_ec2_transit_gateway_route_table.tgw_rt : k => v.id }
}

output "attachment_ids" {
  value = { for k, v in aws_ec2_transit_gateway_vpc_attachment.vpc_tgw_attach : k => v.id }
}

output "tgw_arn" {
  value = aws_ec2_transit_gateway.multi_tgw.arn
}


# For tgw peering module
output "tgw_route_table_id" {
  description = "The default route table ID for the Transit Gateway"
  value       = aws_ec2_transit_gateway.multi_tgw.association_default_route_table_id
}