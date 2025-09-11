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


# Block public access
# Enable Block Public Access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Enforce ACL for log delivery
# Set the ACL for the log bucket to allow Log Delivery group to write logs
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}


# HTTPS only policy and Log delivery policy (scoped to this bucket only)
# Creates Bucket Policy to enforce HTTPS only access and to allow AWS Log Delivery Service to write logs to the bucket
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Enforce HTTPS-only
      {
        Sid       = "HTTPSOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          aws_s3_bucket.log_bucket.arn,
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },

      # Allow AWS log delivery
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
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


