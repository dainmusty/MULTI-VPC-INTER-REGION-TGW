# Create RAM Resource Share
resource "aws_ram_resource_share" "tgw_share" {
  name                      = var.name
  allow_external_principals = false

  tags = var.tags
}


# Resource Associations
resource "aws_ram_resource_association" "resource_assoc" {
  for_each = var.tgw_arns

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

# Principal Associations
resource "aws_ram_principal_association" "principal_assoc" {
  for_each           = toset(var.principals)
  principal          = each.value
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}
