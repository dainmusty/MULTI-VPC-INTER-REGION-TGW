terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}



terraform {
  required_version = ">= 1.5.0"
}
