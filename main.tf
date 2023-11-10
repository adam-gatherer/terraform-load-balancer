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

  # Removed to see if it will figure it out on its own
  #shared_config_files       = ["/Path/to/.aws/config"] # Example path whilst I figure out how to do this correctly
  #shared_credentials_files  = ["/Path/to/.aws/credentials"] # As above
  #profile                   = "PROFILE"
}