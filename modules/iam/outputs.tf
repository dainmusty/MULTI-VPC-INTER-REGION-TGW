
output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.arn
}

output "vpc_flow_log_role_arn" {
  description = "ARN of the VPC Flow Log Role"
  value       = aws_iam_role.vpc_flow_logs.arn

}