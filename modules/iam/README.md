# To create IRSA for AlB controller dynamically without creating iam role and its policy attachment manually use;
# IAM Role for IRSA for the AWS Load Balancer Controller
module "eks_irsa_alb_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0" # Adjust version as needed
  role_name = "alb-controller-irsa"
  attach_load_balancer_controller_policy = false
  cluster_name = var.cluster_name
  oidc_providers = {
    main = {
      provider_arn = data.aws_eks_cluster.eks.identity[0].oidc.issuer
    }
  }
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  irsa_config = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  }
}


# IAM Role for ALB Controller
resource "aws_iam_role" "alb_controller_irsa" {
  name               = "eks-alb-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_oidc_trust.json
}

# Attach AWS Managed IAM Policy to Role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}

# Custom IAM Policy (if not using AWS managed one)
# resource "aws_iam_policy" "aws_load_balancer_controller" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   description = "Policy for AWS ALB Controller"
#   policy = file("${path.module}//../../scripts/alb-policy.json")
# }


# Custom basded policy Attachment
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# # AWS Managed IAM Policy (if you want to use an AWS managed policy 
# resource "aws_iam_role_policy_attachment" "alb_controller" {
#   role       = aws_iam_role.alb_controller_irsa.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
# }


# IAM Role for Grafana to access AWS Secrets Manager
# 1. IAM Policy to allow access to specific secret
# resource "aws_iam_policy" "grafana_secrets_access" {
#   name        = "grafana-secretsmanager-access"
#   description = "Allow read-only access to Grafana admin secret"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ],
#         Resource = var.grafana_admin_secret_arn
#       }
#     ]
#   })
# }


# final iam for alb
locals {
  # Extracts the OIDC provider ID from the full ARN (e.g. oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E)
  oidc_provider_id = replace(var.oidc_provider_arn, "https://", "")
}

# Trust Policy for ALB Controller IAM Role
data "aws_iam_policy_document" "alb_controller_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:kube-system:alb-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM Role to be assumed by the ALB Controller via IRSA
resource "aws_iam_role" "alb_controller_irsa" {
  name               = "eks-alb-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_oidc_trust.json
}

# IAM Policy for ALB Controller (can be AWS managed or custom file)
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS ALB Controller"
  policy      = file("${path.module}/../../scripts/alb-policy.json")
}

# Attach IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa.name
}

# old setup for alb iam

# Define local variable to extract OIDC provider ID from ARN
locals {
  oidc_provider_id = replace(var.oidc_provider_arn, "https://", "")
}

# OIDC Trust Policy for ALB Controller
data "aws_iam_policy_document" "alb_controller_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

# IAM Role for ALB Controller
resource "aws_iam_role" "alb_controller_irsa" {
  name               = "eks-alb-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_oidc_trust.json
}

# Custom IAM Policy (if not using AWS managed one)
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS ALB Controller"
  policy = file("${path.module}//../../scripts/alb-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa.name
}


why is this repeated
"arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/*"
ChatGPT said:

Good catch 👌 — that’s not a mistake, it’s intentional.

Here’s why you see both:

arn:aws:s3:::${var.log_bucket_name} → refers to the bucket itself (needed for actions like s3:GetBucketAcl, s3:GetBucketPolicy).

arn:aws:s3:::${var.log_bucket_name}/* → refers to all objects inside the bucket (needed for s3:PutObject).

🔎 Example:

If you only had the bucket ARN → AWS would let you read bucket properties, but you couldn’t put objects inside it.

If you only had the object ARN → AWS would let you interact with objects, but you couldn’t query ACLs or bucket-level settings.

That’s why AWS best practice is to include both when you’re mixing bucket-level and object-level permissions.

# More permission boundaries

#       ,
#       {
#         Sid    = "AllowEKSManagement",
#         Effect = "Allow",
#         Action = [
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "eks:UpdateClusterConfig"
#         ],
#         Resource = "arn:aws:eks:${var.region}:${var.account_id}:cluster/*"
#       },
#       {
#         Sid    = "AllowEC2Networking",
#         Effect = "Allow",
#         Action = [
#           "ec2:Describe*",
#           "ec2:CreateTags",
#           "ec2:DeleteTags"
#         ],
#         Resource = "*"
#       },
#       {
#         Sid    = "AllowRDSManagement",
#         Effect = "Allow",
#         Action = [
#           "rds:Describe*"
#         ],
#         Resource = "arn:aws:rds:${var.region}:${var.account_id}:db:*"
#       },
#       {
#         Sid    = "AllowConfigRead",
#         Effect = "Allow",
#         Action = [
#           "config:Describe*",
#           "config:Get*",
#           "config:List*"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# policy allows VPC Flow Logs → CloudWatch:

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}


3. Do all future roles need the boundary?

👉 Not necessarily.
It depends on your organization’s governance/security model:

Strict environments (enterprise / regulated) → Yes, every IAM role must use the permission boundary (set at org level via SCP or Terraform).

Flexible/dev environments → You can apply boundaries selectively (e.g., only for logging/infra roles).

In your case, since you’re only deploying VPCs, TGWs, and logs, you don’t need a boundary for all roles yet. You can introduce it gradually.

✅ Recommendation:

Start with the vpc_flow_logs role using the permission boundary.

Later, when you add app/service roles, decide whether to enforce boundaries org-wide.


# oidc terraform role; use this for more security
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:dainmusty/MULTI-VPC-INTER-REGION-TGW:ref:refs/heads/main",
            "repo:dainmusty/MULTI-VPC-INTER-REGION-TGW:ref:refs/heads/dev"
          ]
        }
      }
    }
  ]
}
