# vpc
resource "aws_vpc" "eu-north-vpc" {
  cidr_block = var.vpc_cidr
    tags = {
        Name = "eu-north-vpc"
    }
  enable_dns_support = true
  }

#   Subnet: Public Subnet_1
resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.eu-north-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-north-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "subnet_1"
    }
}

#   Subnet: Public Subnet_2
resource "aws_subnet" "subnet_2" {
    vpc_id = aws_vpc.eu-north-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-north-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "Subnet_2"
    }
}

#  Internet Gateway: Attach to VPC
resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.eu-north-vpc.id
  tags = {
    Name = "igw_1"
  }
}

# Route Table: Public Route Table
resource "aws_route_table" "RT_1" {
    vpc_id = aws_vpc.eu-north-vpc.id
    tags = {
      Name = "RT_1"
    }
    route {
        gateway_id = aws_internet_gateway.igw_1.id
        cidr_block = "0.0.0.0/0"
    }
}

# Route Table Association: Associate Subnets with Route Tables
resource "aws_route_table_association" "RT_1_assoc" {
    subnet_id      = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.RT_1.id
}

# Route Table Association: Associate Subnets with Route Tables
resource "aws_route_table_association" "RT_2_assoc" {
    subnet_id      = aws_subnet.subnet_2.id
    route_table_id = aws_route_table.RT_1.id
}

# Security Group: Allow HTTP and SSH
resource "aws_security_group" "sg1" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.eu-north-vpc.id
  tags = {
    Name = "sg1"
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket: Create an S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "masadsubhani8"
}

# Server: 1 Instance
resource "aws_instance" "server_1" {
  ami = var.ami_id
  instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.sg1.id]
    subnet_id = aws_subnet.subnet_1.id
    user_data =  base64encode(file("userdata.sh"))
  tags = {
    Name = "Server1"
  }
  key_name = var.key_name
}

# Server: 2 Instance
resource "aws_instance" "server_2" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id = aws_subnet.subnet_2.id
  user_data = base64encode(file("userdata1.sh"))
  tags = {
    Name = "Server2"
  }
  key_name = var.key_name
}

# Elastic Load Balancer: Create an Application Load Balancer
resource "aws_lb" "app_lb" {
    name = "app-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sg1.id]
    subnets = [
        aws_subnet.subnet_1.id,
        aws_subnet.subnet_2.id,
    ]
    tags = {
        Name = "app-lb" 
    }
}

# Target Group: Create a target group for the load balancer
resource "aws_lb_target_group" "tg1" {
    name     = "tg1"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.eu-north-vpc.id
    health_check {
        path                = "/"
        port                = "traffic-port"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }
    tags = {
        Name = "tg1"
    }
}

# Associate the instances with the target group
resource "aws_lb_target_group_attachment" "attachment1" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.server_1.id
  port             = 80
}

# Associate the instances with the target group
resource "aws_lb_target_group_attachment" "attachment2" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.server_2.id
  port             = 80
}

# Listener: Create a listener for the load balancer
resource "aws_lb_listener" "listener1" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }
}

# Output: Load Balancer DNS Name
output "load_balancer_dns_name" {
  value = aws_lb.app_lb.dns_name
  description = "The DNS name of the Application Load Balancer"
}


