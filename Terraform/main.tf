locals {
  required_tags = {
    project = var.project_name
    environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
}

locals {
  name_suffix = "${var.project_name}-${var.environment}"
}

terraform {
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

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
  version =  "~> 2.0"
}

# resource <type> <name>. Single infra config
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c94855ba95c71c99" # Amz Machine Img
  instance_type = "t2.micro"

  tags = {
    Name = "var.instance_name"
  }
}

# Module: Multi resource config
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  # vide locals
  name = "vpc-${local.name_suffix}" 
  tags = local.tags
}

