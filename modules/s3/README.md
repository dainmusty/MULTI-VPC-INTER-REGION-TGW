# S3 Bucket Module

This Terraform module creates an Amazon S3 bucket with optional versioning support.

## Inputs

| Name              | Description                          | Type          | Default  | Required |
|-------------------|--------------------------------------|---------------|----------|----------|
| bucket_name       | The name of the S3 bucket            | `string`      | n/a      | yes      |
| acl               | The canned ACL to apply              | `string`      | `private`| no       |
| versioning_enabled| Enable versioning on the bucket      | `bool`        | `false`  | no       |
| tags              | Tags to apply to the bucket          | `map(string)` | `{}`     | no       |

## Outputs

| Name         | Description                 |
|--------------|-----------------------------|
| bucket_arn   | The ARN of the bucket       |
| bucket_name  | The name of the bucket      |

## Usage


module "s3" {
  source            = "./modules/s3"
  bucket_name       = "my-s3-bucket-name"
  acl               = "private"
  versioning_enabled = true
  tags = {
    Environment = "dev"
    Team        = "DevOps"
  }
}


module.s3.aws_s3_bucket.s3_bucket will be destroyed
  - resource "aws_s3_bucket" "s3_bucket" {
      - arn                         = "arn:aws:s3:::gnpc-dev-bucket" -> null
      - bucket                      = "gnpc-dev-bucket" -> null
      - bucket_domain_name          = "gnpc-dev-bucket.s3.amazonaws.com" -> null
      - bucket_regional_domain_name = "gnpc-dev-bucket.s3.us-east-1.amazonaws.com" -> null
      - force_destroy               = false -> null
      - hosted_zone_id              = "Z3AQBSTGFYJSTF" -> null
      - id                          = "gnpc-dev-bucket" -> null
      - object_lock_enabled         = false -> null
      - region                      = "us-east-1" -> null
      - request_payer               = "BucketOwner" -> null
      - tags                        = {
          - "Name" = "GNPC-Dev-gnpc-dev-bucket"
        } -> null
      - tags_all                    = {
          - "Name" = "GNPC-Dev-gnpc-dev-bucket"
        } -> null
        # (3 unchanged attributes hidden)

      - grant {
          - id          = "c55ad48d0b76c57ece4b7ab46630353c560493d3fd5802cc5d91aa2a2383cf59" -> null       
          - permissions = [
              - "FULL_CONTROL",
            ] -> null
          - type        = "CanonicalUser" -> null
            # (1 unchanged attribute hidden)
        }

      - server_side_encryption_configuration {
          - rule {
              - bucket_key_enabled = false -> null

              - apply_server_side_encryption_by_default {
                  - sse_algorithm     = "AES256" -> null
                    # (1 unchanged attribute hidden)
                }
            }
        }

      - versioning {
          - enabled    = false -> null
          - mfa_delete = false -> null
        }
    }


    
╵
╷
│ Error: expected versioning_configuration.0.status to be one of ["Enabled" "Suspended" "Disabled"], got enabled



what is best practise? should i put the bucket policy in the s3 child or the iam child module?

Best practice is to put the S3 bucket policy in the S3 (storage) child module, not the IAM module. Here’s why:

✅ Reasons to Put the Bucket Policy in the S3 Module
Principle	Explanation
Resource ownership	The bucket policy is tightly coupled to the S3 bucket.
Encapsulation	Keep all logic and permissions for the bucket in one place.
Least surprise	Future users expect bucket policies to be in the same module as the bucket.
IAM != bucket policies	IAM policies attach to users/roles; bucket policies belong to S3 itself.
Reusability	Makes the S3 module fully reusable, even in accounts that don’t share IAM.

❌ Why Not Put It in the IAM Module?
Bucket policies aren’t IAM policies — they’re part of the S3 resource definition.

Mixing them in the IAM module creates tight coupling between unrelated concerns.

Makes your IAM module less portable and harder to test.

✅ Recommended Structure
If your Terraform project has modules like:


modules/
  s3/
    main.tf        <-- include aws_s3_bucket and aws_s3_bucket_policy here
  iam/
    main.tf        <-- roles, policies, etc.
Then keep aws_s3_bucket_policy inside the s3/ module alongside aws_s3_bucket.