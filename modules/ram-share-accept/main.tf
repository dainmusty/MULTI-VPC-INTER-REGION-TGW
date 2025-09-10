resource "aws_ram_resource_share_accepter" "share_accepters" {
  for_each = var.accept_share ? { for idx, arn in var.share_arns : idx => arn } : {}

  share_arn = each.value
}
