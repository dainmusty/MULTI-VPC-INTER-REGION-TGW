variable "env" {
  description = "Environment"
  type = string
  
}


variable "company_name" {
  description = "Company that owns the Infrastructure"
  type = string
  
}

variable "log_bucket_name" {
  description = "Bucket name"
  type = string
}




# 
# variable "eks_node_role_principals" {
#   description = "List of service principals for EKS node role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "eks_node_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for EKS node role"
#   type        = string
#   default     = null
# }

# variable "eks_cluster_role_principals" {
#   description = "List of service principals for EKS cluster role"
#   type        = list(string)
#   default     = ["eks.amazonaws.com"]
# }

# variable "eks_cluster_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for EKS cluster role"
#   type        = string
#   default     = null
# }

# variable "prometheus_role_principals" {
#   description = "List of service principals for Prometheus role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "prometheus_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for Prometheus role"
#   type        = string
#   default     = null
# }

# variable "grafana_role_principals" {
#   description = "List of service principals for Grafana role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "grafana_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for Grafana role"
#   type        = string
#   default     = null
# }

# variable "s3_rw_role_principals" {
#   description = "List of service principals for S3 RW role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "s3_rw_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for S3 RW role"
#   type        = string
#   default     = null
# }

# variable "config_role_principals" {
#   description = "List of service principals for AWS Config role"
#   type        = list(string)
#   default     = ["config.amazonaws.com"]
# }

# variable "config_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for AWS Config role"
#   type        = string
#   default     = null
# }

# variable "admin_role_principals" {
#   description = "List of service principals for admin role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "admin_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for admin role"
#   type        = string
#   default     = null
# }

# variable "s3_full_access_role_principals" {
#   description = "List of service principals for S3 Full Access role"
#   type        = list(string)
#   default     = ["ec2.amazonaws.com"]
# }

# variable "s3_full_access_permissions_boundary_arn" {
#   description = "ARN of the permissions boundary for S3 Full Access role"
#   type        = string
#   default     = null
# }

# variable "env" {
#   description = "Environment"
#   type = string
# }

# variable "company_name" {
#   description = "Company that owns the Infrastructure"
#   type = string
# }

# variable "operations_bucket_arn" {
#   description = "ARN of Operations Bucket"
#   type = string
# }

# variable "log_bucket_arn" {
#   description = "ARN of the S3 bucket for S3 RW access"
#   type        = string
# }

# variable "oidc_provider_arn" {
#   description = "ARN of the OIDC provider"
#   type        = string
# }   

# variable "grafana_secret_name" {
#   description = "Name of the secret containing Grafana admin credentials"
#   type        = string 
# }

# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }






