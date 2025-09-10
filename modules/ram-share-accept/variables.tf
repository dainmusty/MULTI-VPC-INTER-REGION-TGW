variable "share_arns" {
  description = "List of RAM share ARNs to accept"
  type        = list(string)
}

variable "accept_share" {
  description = "Whether to accept the RAM shares"
  type        = bool
  default     = true
}
