terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

terraform {
  required_version = ">= 1.5.0"
}

# -----------------------
# Management Account Providers
# -----------------------

provider "aws" {
  alias  = "mgmt_us_east_1" # Virginia
  region = "us-east-1"
}

provider "aws" {
  alias  = "mgmt_us_east_2" # Ohio
  region = "us-east-2"
}

# -----------------------
# Dev Account Providers
# -----------------------

provider "aws" {
  alias  = "dev_us_east_1" # if dev ever needs resources in Virginia
  region = "us-east-1"
}

provider "aws" {
  alias  = "dev_us_east_2" # Ohio
  region = "us-east-2"
}

# -----------------------
# Prod Account Providers
# -----------------------

# provider "aws" {
#   alias  = "prod_us_east_1" # Virginia
#   region = "us-east-1"
# }

# provider "aws" {
#   alias  = "prod_us_east_2" # Ohio
#   region = "us-east-2"
# }