provider "aws" {
  region = var.region
}

# Minimal VPC + subnet for the example — not part of the ec2 module itself.
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "ec2-module-example" }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "ec2-module-example" }
}

resource "aws_security_group" "example" {
  name        = "ec2-module-example"
  description = "Example security group for the EC2 module"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-module-example" }
}

module "ec2" {
  source = "../../"

  name                   = "example-instance"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.example.id
  vpc_security_group_ids = [aws_security_group.example.id]

  root_volume_size      = 20
  root_volume_type      = "gp3"
  root_volume_encrypted = true

  monitoring  = true
  create_eip  = false

  additional_ebs_volumes = [
    {
      device_name = "/dev/sdf"
      size        = 50
      type        = "gp3"
      encrypted   = true
    }
  ]

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
