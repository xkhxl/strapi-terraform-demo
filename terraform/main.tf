terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = var.aws_region
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}


resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow SSH, Strapi, and Postgres within SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Strapi HTTP"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Postgres within SG"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "strapi-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "strapi-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_db_instance" "strapi_db" {
  allocated_storage = 20
  engine            = "postgres"
  instance_class    = var.rds_instance_class

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
}

locals {
  user_data = templatefile("${path.module}/user_data.tpl", {
    rds_endpoint = aws_db_instance.strapi_db.address,
    db_password  = var.db_password,
    repo_url     = "https://github.com/xkhxl/strapi-terraform-demo.git",
    key_user     = "ubuntu",
    REPO_DIR     = "/home/ubuntu/strapi-terraform-demo",
    DOCKER_DIR   = "/home/ubuntu/strapi-terraform-demo/docker",
    RDS_CA_DIR   = "/home/ubuntu/rds-ca"
  })
}


resource "aws_instance" "strapi_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name               = var.ec2_key_name

  user_data = local.user_data

  depends_on = [aws_db_instance.strapi_db]

  tags = {
    Name = "strapi-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.strapi_db.address
}

output "strapi_url" {
  value = "http://${aws_instance.strapi_server.public_ip}:1337"
}
