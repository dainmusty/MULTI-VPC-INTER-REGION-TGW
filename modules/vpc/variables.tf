variable "vpcs" {
  type = map(object({
    cidr_block          = string
    azs                 = list(string)
    public_subnet_cidrs = list(string)
    private_subnet_cidrs = list(string)
  }))
}


variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "public_rt_destination_cidr_block" {
  description = "Destination CIDR for public route (usually 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_rt_destination_cidr_block" {
  description = "Destination CIDR for private route (usually 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}
