variable "peerings" {
  description = "Map of TGW peerings and their route CIDRs"
  type = map(object({
    requester_tgw_id = string
    accepter_tgw_id  = string
    accepter_region  = string
    requester_rt_id  = string
    accepter_rt_id   = string
    requester_routes = list(string)
    accepter_routes  = list(string)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
