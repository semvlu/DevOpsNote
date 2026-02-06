provider "aws" {
  region = "us-west-2"
}


# resource <type> <name>. Single infra config
# Concepts: for_each
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

locals {
  iter = toset([
    "first",
    "second",
    "third"
  ])
}

resource "aws_instance" "app_server" {
  for_each = local.iter
  ami           = "ami-0c94855ba95c71c99" # Amz Machine Img
  instance_type = "t2.micro"

  subnet_id = each.key

  tags = {
    Name = "var.instance_name"
  }
}


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
# Module: Multi resource config
module "vpc" {
  count = 5
  source = "terraform-aws-modules/vpc/aws"
  # local: dir path
  # Github: URL
  version = "2.66.0"

  # Input var
  # vide locals
  name = "vpc-${local.name_suffix}" 
  tags = local.tags

}