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


🔎 What’s happening

You configured 4 AWS providers with aliases (mgmt_us_east_1, mgmt_us_east_2, dev_us_east_1, dev_us_east_2).

Terraform expects all of them to have valid credentials.

Right now, your GitHub Actions workflow sets AWS creds once (default profile).

But your provider blocks don’t reference a profile or assume role, so Terraform tries IMDS (EC2 metadata service) → fails (since GitHub runners aren’t EC2).


That’s why you see repeated errors:

Error: No valid credential sources found
Error: failed to refresh cached credentials, no EC2 IMDS role found

✅ Solutions (pick one depending on your setup)
Option 1: Same account across all regions

If all these aliases (mgmt / dev) use the same AWS account credentials, then you don’t need multiple profiles — just let them inherit from the default provider:

provider "aws" {
  alias  = "mgmt_us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "mgmt_us_east_2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "dev_us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dev_us_east_2"
  region = "us-east-2"
}


👉 With aws-actions/configure-aws-credentials, Terraform automatically picks up AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from the environment. No profile needed.

Option 2: Different AWS accounts (management vs dev)

If mgmt and dev are different AWS accounts, you need to tell each provider block how to authenticate.

That means either:

Use different credentials for each account → pass them as secrets:

provider "aws" {
  alias   = "mgmt_us_east_1"
  region  = "us-east-1"
  profile = "mgmt"
}

provider "aws" {
  alias   = "dev_us_east_2"
  region  = "us-east-2"
  profile = "dev"
}


And in your workflow:

- name: Configure AWS credentials (Mgmt)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_MGMT_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_MGMT_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
    role-session-name: mgmt-session
    role-to-assume: arn:aws:iam::<mgmt-account-id>:role/<mgmt-role>

- name: Configure AWS credentials (Dev)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_DEV_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_DEV_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
    role-session-name: dev-session
    role-to-assume: arn:aws:iam::<dev-account-id>:role/<dev-role>


Then Terraform providers will resolve based on profiles.

Use assume_role directly in providers.tf:

provider "aws" {
  alias   = "mgmt_us_east_1"
  region  = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${var.management_account_id}:role/AdminRole"
    session_name = "mgmt-session"
  }
}


👉 This way, you configure AWS creds once (dev account), and Terraform assumes roles for other accounts.

🔧 What I’d recommend

If all accounts are the same → Option 1 (simplest).

If different accounts (mgmt/dev/prod) → Option 2 with assume_role (best practice, fewer secrets to manage).


2. Missing provider version constraint

TFLint flags resources where you’re using aws_* without defining required_providers.

Fix by adding inside your terraform block:

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}


👉 Do this in the root module and each child module where provider resources are declared.
This ensures your modules are always pinned to a compatible provider version.