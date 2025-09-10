variable "requester_tgw_id" {
  description = "Transit Gateway ID of the requester"
  type        = string
}

variable "requester_region" {
  description = "AWS region of the requester TGW"
  type        = string
}

variable "accepter_tgw_id" {
  description = "Transit Gateway ID of the accepter"
  type        = string
}

variable "accepter_region" {
  description = "AWS region of the accepter TGW"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

