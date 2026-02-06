terraform {
  backend "s3" {
    bucket         = ""
    key            = "./<name>.tfstate" # path to state file
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
  
  # Apply when using HCP terraform
  cloud {
      organization = "orgName"
      workspaces {
        name = "name"
      }
  }

  required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 4.16"
      }
  }

  required_version = ">= 1.12.0"
}
