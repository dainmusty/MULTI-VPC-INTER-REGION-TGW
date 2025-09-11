# -----------------------
# Ohio VPCs
# -----------------------
module "ohio_vpcs" {
  source    = "../../modules/vpc"
  providers = { 
    aws = aws.dev_us_east_2
  }

  vpcs = {
    vpc1 = {
      cidr_block           = "10.1.0.0/16"   
      azs                  = ["us-east-2a", "us-east-2b"]
      public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24"]

      # 🔽 Flow logs config
      enable_flow_logs           = true       # Enable VPC flow logs
      flow_logs_destination_type = "s3"       # change to "cloud-watch-logs" if using CloudWatch Logs
      flow_logs_destination_arn  = module.s3.log_bucket_arn
      flow_logs_traffic_type     = "ALL"        # ACCEPT → capture only accepted traffic. # REJECT → capture only rejected traffic. ALL → capture all traffic.
      vpc_flow_log_iam_role_arn  = null       # Provide iam role if using CloudWatch Logs
      env = "dev"
    }
    vpc2 = {
      cidr_block           = "10.2.0.0/16"   
      azs                  = ["us-east-2a", "us-east-2b"]
      public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
      private_subnet_cidrs = ["10.2.101.0/24", "10.2.102.0/24"]

      # 🔽 Flow logs config
      enable_flow_logs           = true       # Enable VPC flow logs
      flow_logs_destination_type = "s3"      # change to "cloud-watch-logs" if using CloudWatch Logs  
      flow_logs_destination_arn  = module.s3.log_bucket_arn
      flow_logs_traffic_type     = "ALL"      # ACCEPT → capture only accepted traffic. # REJECT → capture only rejected traffic. ALL → capture all traffic.
      vpc_flow_log_iam_role_arn  = null
      env = "dev"


    }
  }



  tags = {
    Region = "ohio"
    Env    = "dev"
  }
}



# -----------------------
# Virginia VPCs
# -----------------------
module "virginia_vpcs" {
  source    = "../../modules/vpc"
  providers = { aws = aws.dev_us_east_1 }

  vpcs = {
    vpc3 = {
      cidr_block          = "10.3.0.0/16"   
      azs                 = ["us-east-1a", "us-east-1b"]
      public_subnet_cidrs = ["10.3.1.0/24", "10.3.2.0/24"]
      private_subnet_cidrs= ["10.3.101.0/24", "10.3.102.0/24"]

      # 🔽 Flow logs config
      enable_flow_logs           = true       # Enable VPC flow logs
      flow_logs_destination_type = "s3"      # change to "cloud-watch-logs" if using CloudWatch Logs
      flow_logs_destination_arn  = module.s3.log_bucket_arn
      flow_logs_traffic_type     = "ALL"      # ACCEPT → capture only accepted traffic. # REJECT → capture only rejected traffic. ALL → capture all traffic.
      vpc_flow_log_iam_role_arn  = null       # Provide iam role if using CloudWatch Logs. You need call the iam child module before referencing the role arn here.
      env = "dev"
    }
    vpc4 = {
      cidr_block          = "10.4.0.0/16"   
      azs                 = ["us-east-1a", "us-east-1b"]
      public_subnet_cidrs = ["10.4.1.0/24", "10.4.2.0/24"]
      private_subnet_cidrs= ["10.4.101.0/24", "10.4.102.0/24"]

      # 🔽 Flow logs config
      enable_flow_logs           = true       # Enable VPC flow logs
      flow_logs_destination_type = "s3"      # change to "cloud-watch-logs" if using CloudWatch Logs
      flow_logs_destination_arn  = module.s3.log_bucket_arn
      flow_logs_traffic_type     = "ALL"      # "ACCEPT" → capture only accepted traffic. # "REJECT" → capture only rejected traffic. "ALL" → capture all traffic.
      vpc_flow_log_iam_role_arn  = null       # Replace null with "module.iam.vpc_flow_log_role_arn" if using CloudWatch Logs. You need call the iam child module before referencing the role arn here.
      env = "dev"


    }
  }
  tags = {
    Region = "virginia"
    Env    = "dev"
  }

}


# # S3 Module
module "s3" {
  source                          = "../../modules/s3"
  
  log_bucket_name                      = "tankofm-dev-log-bucket"
  log_bucket_versioning_status = "Enabled"
  ResourcePrefix                  = "Tankofm-Dev"
 

}


# IAM Module
module "iam" {
  source = "../../modules/iam"
  env = "dev"
  company_name = "tankofm"
  
}




# 3) TGW in Ohio (auto-attach selected VPCs)
module "tgw_ohio" {
  source    = "../../modules/tgw"
  providers = { aws = aws.dev_us_east_2 }

  project          = "tankofm-inter-region-vpc-project"
  tgw_name         = "tgw_ohio"
  route_table_names = ["prod", "dev"]

  amazon_side_asn                 = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  attachments = {
    vpc1 = {
      vpc_id         = module.ohio_vpcs.vpc_ids["vpc1"]
      subnet_ids     = module.ohio_vpcs.private_subnet_ids["vpc1"]
      associate_with = "prod"
      propagate_to   = "prod"
    }
    vpc2 = {
      vpc_id         = module.ohio_vpcs.vpc_ids["vpc2"]
      subnet_ids     = module.ohio_vpcs.private_subnet_ids["vpc2"]
      associate_with = "prod"
      propagate_to   = "prod"
    }
  }

  tags = {
    Region = "ohio"
    Env    = "dev"
  }
}


# 4) TGW in Virginia (attach different VPCs)
module "tgw_virginia" {
  source    = "../../modules/tgw"
  providers = { aws = aws.dev_us_east_1 }

  project          = "tankofm-inter-region-vpc-project"
  tgw_name         = "tgw_virginia"
  route_table_names = ["prod", "dev"]

  amazon_side_asn                 = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  attachments = {
    vpc1 = {
      vpc_id         = module.virginia_vpcs.vpc_ids["vpc3"]
      subnet_ids     = module.virginia_vpcs.private_subnet_ids["vpc3"]
      associate_with = "prod"
      propagate_to   = "prod"
    }
    vpc2 = {
      vpc_id         = module.virginia_vpcs.vpc_ids["vpc4"]
      subnet_ids     = module.virginia_vpcs.private_subnet_ids["vpc4"]
      associate_with = "prod"
      propagate_to   = "prod"
    }
  }

  tags = {
    Region = "virginia"
    Env    = "dev"
  }
}



# 5) TGW Peering between Ohio and Virginia
# module "tgw_peering_ohio_virginia" {
#   source = "../modules/tgw-peering"

#   providers = {
#     aws.requester = aws.network_virginia
#     aws.accepter  = aws.network_ohio
#   }

#   requester_tgw_id = module.tgw_virginia.tgw_id
#   requester_region = "us-east-1"
  

#   accepter_tgw_id  = module.tgw_ohio.tgw_id
#   accepter_region  = "us-east-2"

#   tags = {
#     Project = "tankofm-inter-region-vpc-project"
#     Env     = "dev"
#   }
# }


# # 6) Define peerings (flexible for cross-account/region)
# module "tgw_peerings" {
#   source = "../modules/multi-tgw-peering"

#   providers = {
#     aws.requester = aws.network_virginia
#     aws.accepter  = aws.network_ohio
#   }

#   peerings = {
#     virginia_ohio_primary = {
#       requester_tgw_id = module.tgw_virginia.tgw_id
#       accepter_tgw_id  = module.tgw_ohio.tgw_id
#       accepter_region  = "us-east-2"
#     }

#     # Add more peerings as needed with the provider aliases
#       # add more Virginia<->Ohio peerings here. for example:
#     # virginia-ohio-secondary = {
#     #   requester_tgw_id = module.tgw_virginia.tgw_id
#     #   accepter_tgw_id  = module.tgw_ohio_secondary.tgw_id
#     #   accepter_region  = "us-west-2"
    
#   }

#   tags = {
#     Project = "tankofm-inter-region-vpc-project"
#     Env     = "dev"
#   }
# }


# 7) Define cross-account peerings (flexible for cross-account/region)
module "tgw_peering_virginia_ohio" {
  source = "../../modules/multi-acc-tgw-peering"

  providers = {
    aws.requester = aws.dev_us_east_1
    aws.accepter  = aws.dev_us_east_2
  }

  peerings = {
    virginia-ohio = {
      requester_tgw_id = module.tgw_virginia.tgw_id
      accepter_tgw_id  = module.tgw_ohio.tgw_id
      accepter_region  = "us-east-2"
      requester_rt_id  = module.tgw_virginia.tgw_route_table_id
      accepter_rt_id   = module.tgw_ohio.tgw_route_table_id
      requester_routes = values(module.ohio_vpcs.vpc_cidrs)      # from Ohio VPC outputs
      accepter_routes  = values(module.virginia_vpcs.vpc_cidrs)  # from Virginia VPC outputs
    }
  }

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "dev"
  }
}



# 8) TGW RAM Share

# Share Virginia TGW with Management Account
module "tgw_ram_share_virginia" {
  source = "../../modules/ram-share"

  providers = {
    aws = aws.mgmt_us_east_1
  }

  name       = "network-tgw-share-virginia"
  principals = [var.management_account_id]

  tgw_arns = {
    virginia = module.tgw_virginia.tgw_arn
  }

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "dev"
  }
}

# Share Ohio TGW with Dev Account
module "tgw_ram_share_ohio" {
  source = "../../modules/ram-share"

  providers = {
    aws = aws.mgmt_us_east_2
  }

  name       = "network-tgw-share-ohio"
  principals = [var.dev_account_id]

  tgw_arns = {
    ohio = module.tgw_ohio.tgw_arn
  }

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "dev"
  }
}



# 9) Accept TGW RAM Share in required account
module "ram_share_accept_virginia" {
  source = "../../modules/ram-share-accept"

  providers = {
    aws = aws.mgmt_us_east_1
  }

  share_arns = [module.tgw_ram_share_virginia.share_arn]
  accept_share = true
}

module "ram_share_accept_ohio" {
  source = "../../modules/ram-share-accept"

  providers = {
    aws = aws.mgmt_us_east_2
  }

  share_arns = [module.tgw_ram_share_ohio.share_arn]
  accept_share = true
}
