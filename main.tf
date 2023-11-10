terraform {

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>4.0"
      }
    }
}

# Configruing the AWS Provider

provider "aws" {
  region                    = "us-east-1"
  shared_config_files       = ["/Path/to/.aws/config"]
  shared_credentials_files  = ["Path/to/.aws/credentials"]
  profile                   = "PROFILE"
}