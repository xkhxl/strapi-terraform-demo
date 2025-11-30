variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "ec2_instance_type" {
  default = "t3.micro"
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "strapidb"
}

variable "db_user" {
  default = "strapi"
}

variable "db_password" {
  description = "DB password - override with terraform.tfvars or -var"
  default     = "ChangeMe123!"
}

variable "my_ip_cidr" {
  description = "Your public IP /32 for SSH (or 0.0.0.0/0 to allow all)"
  default     = "106.222.228.166/32"
}

variable "ec2_key_name" {
  description = "Existing EC2 Key Pair name in AWS to use for SSH access"
  default     = "strapi-key"
}
