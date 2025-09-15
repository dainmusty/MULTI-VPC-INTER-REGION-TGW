variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}


variable "vpcs" {
  description = "Map of VPC configurations"
  type = map(object({
    cidr_block           = string
    azs                  = list(string)
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)

    # 🔽 Flow logs
    enable_flow_logs           = optional(bool, false)
    flow_logs_destination_type = optional(string, "s3")
    flow_logs_destination_arn  = optional(string, null)
    flow_logs_traffic_type     = optional(string, "ALL")
    vpc_flow_log_iam_role_arn  = optional(string, null)
  }))
}
