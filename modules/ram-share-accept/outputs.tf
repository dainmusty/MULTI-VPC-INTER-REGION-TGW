output "accepted_shares" {
  description = "Map of accepted RAM share ARNs and their status"
  value = {
    for k, v in aws_ram_resource_share_accepter.share_accepters :
    k => {
      arn    = v.share_arn
      status = v.status
    }
  }
}

# output "accepted_ram_shares" {
#   value = module.ram_share_accept.accepted_shares
# }