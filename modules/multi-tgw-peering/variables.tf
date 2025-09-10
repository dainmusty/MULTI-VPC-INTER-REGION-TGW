variable "peerings" {
  description = "Map of TGW peerings between a requester and accepter"
  type = map(object({
    requester_tgw_id = string
    accepter_tgw_id  = string
    accepter_region  = string
  }))
}


variable "tags" {
  type    = map(string)
  default = {}
}