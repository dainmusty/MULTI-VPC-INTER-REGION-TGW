module "ec2_ohio" {
  source       = "../modules/ec2"
  name         = "web-server-ohio"
  subnet_id = module.vpc_ohio.public_subnet_ids[0]
  ami          = "ami-0b016c703b95ecbe4" # check your region and update
  key_name     = "us-east-2-musty"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.web_sg_ohio.sg_id]
  providers    = { aws = aws.ohio }
  tags = {
    Name        = "web-server-ohio"
    Environment = "Dev"
  }
}

module "ec2_virginia" {
  source       = "../modules/ec2"
  name         = "web-server-virginia"
  subnet_id = module.vpc_virginia.public_subnet_ids[0]
  ami          = "ami-00ca32bbc84273381" # check your region and update
  key_name     = "us-east-1-musty"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.web_sg_virginia.sg_id]
  providers    = { aws = aws.virginia }
  tags = {
    Name        = "web-server-virginia"
    Environment = "Dev"
  }
}


provider "aws" {
  alias  = "ohio"
  region = "us-east-2"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

module "tgw_multi_region" {
  source  = "../modules/tgw"
  project = "myproject"
  regions = ["ohio", "virginia"]

  amazon_side_asn                 = 64520
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  providers = {
    aws.ohio     = aws.ohio
    aws.virginia = aws.virginia
  }

  tags = {
    Environment = "dev"
  }
}

module "vpcs" {
  source  = "../modules/vpc"
  project = "myproject"

  vpcs = {
    ohio-vpc1 = {
      cidr_block   = "10.0.0.0/16"
      subnet_count = 2
      public_cidrs = ["10.0.1.0/24"]
      private_cidrs = ["10.0.2.0/24"]
    }
    virginia-vpc1 = {
      cidr_block   = "10.1.0.0/16"
      subnet_count = 2
      public_cidrs = ["10.1.1.0/24"]
      private_cidrs = ["10.1.2.0/24"]
    }
  }

  tags = {
    Environment = "dev"
  }

  providers = {
    aws.ohio     = aws.ohio
    aws.virginia = aws.virginia
  }
}


terraform console
> module.ohio_vpcs.private_subnet_ids

assume_role {
    role_arn = "arn:aws:iam::651706774390:role/TerraformRole"
  }


provider "aws" {          # this provider is for network resources in the Ohio. 
  alias  = "network_ohio"
  region = "us-east-2"

  # assume_role {
  #    role_arn     = "arn:aws:iam::********:role/TerraformRole"
  #   session_name = "TerraformSession"
  # }

}

