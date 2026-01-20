provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "terraform-learn-state-vpc" }
}

resource "aws_security_group" "sg_8080" {
  name = "terraform-learn-state-sg-8080"
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.main.id       # Reference to VPC
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_az 

  tags = { Name = "terraform-learn-state-subnet"}
}

resource "aws_instance" "example" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"

  subnet_id = aws_subnet.example.id

  vpc_security_group_ids = [aws_security_group.sg_8080.id]
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              sed -i -e 's/80/8080/' /etc/apache2/ports.conf
              echo "Hello World" > /var/www/html/index.html
              systemctl restart apache2
              EOF
  tags = {
    Name = "terraform-learn-state-ec2"
  }
}

# removed {
#   from = aws_instance.example_new

#   lifecycle {
#     destroy = false
#   }
# }

# resource "aws_instance" "example_new" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t3.micro"
#   vpc_security_group_ids = [aws_security_group.sg_8080.id]
#   user_data              = <<-EOF
#               #!/bin/bash
#               apt-get update
#               apt-get install -y apache2
#               sed -i -e 's/80/8080/' /etc/apache2/ports.conf
#               echo "Hello World" > /var/www/html/index.html
#               systemctl restart apache2
#               EOF
#   tags = {
#     Name = "terraform-learn-state-ec2"
#   }
# }


# terraform apply -var-file="vars.tfvars"
# terraform refresh # get cur state & update 
