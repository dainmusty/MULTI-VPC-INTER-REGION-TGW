# Creates the S3 Bucket for logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket_name

  tags = {
    Name        = "${var.ResourcePrefix}-s3-log-bucket"

  }
}

resource "aws_s3_bucket_versioning" "versioning_log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = var.log_bucket_versioning_status
  }
}

# # Create the Primary S3 Bucket
# resource "aws_s3_bucket" "operations_bucket" {
#   bucket = var.operations_bucket_name

#   tags = {
#     Name        = "${var.ResourcePrefix}-s3-bucket"

#   }
# }

# resource "aws_s3_bucket_versioning" "versioning_operations_bucket" {
#   bucket = aws_s3_bucket.operations_bucket.id
#   versioning_configuration {
#     status = var.operations_bucket_versioning_status
#   }
# }

# resource "aws_s3_bucket_logging" "operations_bucket_logging" {
#   bucket        = aws_s3_bucket.operations_bucket.id
#   target_bucket = aws_s3_bucket.log_bucket.id
#   target_prefix = var.logging_prefix

#   depends_on = [aws_s3_bucket.log_bucket]
# }


# # Creates Replication Destination Bucket
# resource "aws_s3_bucket" "replication_bucket" {
#   bucket = var.replication_bucket_name

#   tags = {
#     Name        = "${var.ResourcePrefix}-s3-replication-destination"
#   }
# }

# resource "aws_s3_bucket_versioning" "versioning_replication_bucket" {
#   bucket = aws_s3_bucket.replication_bucket.id
#   versioning_configuration {
#     status = var.replication_bucket_versioning_status
#   }
# }


# Bucket Policies
# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket_policy" "config_write_policy" {
#   bucket = var.config_bucket_name

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid      = "AWSConfigBucketPermissionsCheck",
#         Effect   = "Allow",
#         Principal = {
#           Service = "config.amazonaws.com"
#         },
#         Action   = "s3:GetBucketAcl",
#         Resource = "arn:aws:s3:::${var.config_bucket_name}"
#       },
#       {
#         Sid      = "AWSConfigBucketDelivery",
#         Effect   = "Allow",
#         Principal = {
#           Service = "config.amazonaws.com"
#         },
#         Action   = [
#           "s3:PutObject",
#           "s3:PutObjectAcl"
#         ],
#         Resource = "arn:aws:s3:::${var.config_bucket_name}/${var.config_key_prefix}/*",
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#           }
#         }
#       }
#     ]
#   })
# }


