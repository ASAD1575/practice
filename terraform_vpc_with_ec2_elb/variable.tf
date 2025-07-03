# AMI ID for the EC2 instance
variable "ami_id" {
  description = "EC2 instance AMI ID"
  type        = string
  default     = "ami-0becc523130ac9d5d"
  
}

# Instace type for the EC2 instance
variable "instance_type" {
    description = "EC2 instance type"
    type        = string
    default     = "t3.micro"
}

# Key pair name for the EC2 instance
variable "key_name" {
    description = "EC2 instance key pair name"
    type        = string
    default     = "aws_login_key"
}

# VPC CIDR block
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}
