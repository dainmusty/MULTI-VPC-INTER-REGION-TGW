# TGW VARIABLES
variable "project" { type = string }
variable "tgw_name" { type = string } # e.g., "tgw_ohio"
variable "route_table_names" {
  type    = list(string)
  default = ["prod", "dev"]
}

variable "amazon_side_asn" {
  type    = number
  default = 64512
}
variable "default_route_table_association" {
  type    = string
  default = "disable"
}
variable "default_route_table_propagation" {
  type    = string
  default = "disable"
}
variable "dns_support" {
  type    = string
  default = "enable"
}
variable "vpn_ecmp_support" {
  type    = string
  default = "enable"
}

variable "attachments" {
  description = <<EOT
Map of VPC attachments:
{
  vpc1 = {
    vpc_id         = "vpc-xxx"
    subnet_ids     = ["subnet-aaa", "subnet-bbb"]
    associate_with = "prod"
    propagate_to   = "prod"
  }
}
EOT
  type = map(object({
    vpc_id         = string
    subnet_ids     = list(string)
    associate_with = string
    propagate_to   = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

