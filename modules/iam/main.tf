resource "aws_iam_role" "terraform_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_principal_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
   tags = var.tags
   
}


resource "aws_iam_role_policy" "terraform_policy" {
  name = "TerraformPolicy"
  role = aws_iam_role.terraform_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*TransitGateway*",
          "ram:*",
          "ec2:Describe*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
