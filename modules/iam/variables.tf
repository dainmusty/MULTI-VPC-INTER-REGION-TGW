variable "trusted_principal_arn" {
  description = "ARN of the IAM user or role allowed to assume this role"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role"
  type = string
}

variable "tags" {
  description = "role tags"
  type = map(string)
}

