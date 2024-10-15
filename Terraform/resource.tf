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
