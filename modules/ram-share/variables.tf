variable "name" {
  type        = string
  description = "Name for the RAM resource share"
}

variable "principals" {
  type        = list(string)
  description = "AWS account IDs to share the TGW with"
}

variable "tgw_arns" {
  description = "Map of TGW ARNs to share"
  type        = map(string)
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags to apply to resources"
}
