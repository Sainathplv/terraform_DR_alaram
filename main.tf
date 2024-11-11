provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}

# Fetch latest Amazon Linux AMI in primary and secondary regions
data "aws_ami" "primary_ami" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "secondary_ami" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Primary and Secondary VPCs
resource "aws_vpc" "primary_vpc" {
  provider   = aws.primary
  cidr_block = var.primary_vpc_cidr
  tags       = { Name = "Primary-VPC" }
}

resource "aws_vpc" "secondary_vpc" {
  provider   = aws.secondary
  cidr_block = var.secondary_vpc_cidr
  tags       = { Name = "Secondary-VPC" }
}

# Primary VPC subnets in different availability zones
resource "aws_subnet" "primary_public_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.primary_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.primary_region}a"
  tags                    = { Name = "Primary-Public-Subnet" }
}

resource "aws_subnet" "primary_public_subnet_2" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.primary_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.primary_region}b"
  tags                    = { Name = "Primary-Public-Subnet-2" }
}

# Secondary VPC subnets in different availability zones
resource "aws_subnet" "secondary_public_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.secondary_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.secondary_region}a"
  tags                    = { Name = "Secondary-Public-Subnet" }
}

resource "aws_subnet" "secondary_public_subnet_2" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.secondary_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.secondary_region}b"
  tags                    = { Name = "Secondary-Public-Subnet-2" }
}

# Internet Gateways for Primary and Secondary VPCs
resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id
  tags     = { Name = "Primary-IGW" }
}

resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id
  tags     = { Name = "Secondary-IGW" }
}

# Security Groups for Load Balancers
resource "aws_security_group" "primary_lb_sg" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  description = "Allow HTTP traffic for primary load balancer"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Primary-LB-SG" }
}

resource "aws_security_group" "secondary_lb_sg" {
  provider    = aws.secondary
  vpc_id      = aws_vpc.secondary_vpc.id
  description = "Allow HTTP traffic for secondary load balancer"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Secondary-LB-SG" }
}

# Load Balancers
resource "aws_lb" "primary_lb" {
  provider           = aws.primary
  name               = "primary-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_lb_sg.id]
  subnets            = [
    aws_subnet.primary_public_subnet.id,
    aws_subnet.primary_public_subnet_2.id
  ]
}

resource "aws_lb" "secondary_lb" {
  provider           = aws.secondary
  name               = "secondary-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_lb_sg.id]
  subnets            = [
    aws_subnet.secondary_public_subnet.id,
    aws_subnet.secondary_public_subnet_2.id
  ]
}

# Target Groups
resource "aws_lb_target_group" "primary_target_group" {
  provider = aws.primary
  name     = "primary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.primary_vpc.id
}

resource "aws_lb_target_group" "secondary_target_group" {
  provider = aws.secondary
  name     = "secondary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.secondary_vpc.id
}

# EC2 Instances
resource "aws_instance" "primary_instance" {
  provider                = aws.primary
  ami                     = data.aws_ami.primary_ami.id
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.primary_public_subnet.id
  vpc_security_group_ids  = [aws_security_group.primary_lb_sg.id]
  tags                    = { Name = "Primary-EC2" }
}

resource "aws_instance" "secondary_instance" {
  provider                = aws.secondary
  ami                     = data.aws_ami.secondary_ami.id
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.secondary_public_subnet.id
  vpc_security_group_ids  = [aws_security_group.secondary_lb_sg.id]
  tags                    = { Name = "Secondary-EC2" }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "primary_tg_attachment" {
  provider         = aws.primary
  target_group_arn = aws_lb_target_group.primary_target_group.arn
  target_id        = aws_instance.primary_instance.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "secondary_tg_attachment" {
  provider         = aws.secondary
  target_group_arn = aws_lb_target_group.secondary_target_group.arn
  target_id        = aws_instance.secondary_instance.id
  port             = 80
}

# Route 53 Zone and Records
resource "aws_route53_zone" "main" {
  name = "sainathportfolioold.netlify.app"
}

resource "aws_route53_record" "primary_dns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.sainathportfolioold.netlify.app"
  type    = "A"
  alias {
    name                   = aws_lb.primary_lb.dns_name
    zone_id                = aws_lb.primary_lb.zone_id
    evaluate_target_health = true
  }
  set_identifier = "Primary-Region"
  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "secondary_dns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.sainathportfolioold.netlify.app"
  type    = "A"
  alias {
    name                   = aws_lb.secondary_lb.dns_name
    zone_id                = aws_lb.secondary_lb.zone_id
    evaluate_target_health = true
  }
  set_identifier = "Secondary-Region"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

# SNS and CloudWatch Alarm
resource "aws_sns_topic" "alarm_topic" {
  name = "cpu_alarm_notifications"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email_notification
}

resource "aws_cloudwatch_metric_alarm" "primary_alarm" {
  provider               = aws.primary
  alarm_name             = "Primary-CPU-Alarm"
  comparison_operator    = "GreaterThanOrEqualToThreshold"
  evaluation_periods     = 2
  metric_name            = "CPUUtilization"
  namespace              = "AWS/EC2"
  period                 = 300
  statistic              = "Average"
  threshold              = 80
  alarm_actions          = [aws_sns_topic.alarm_topic.arn]
  dimensions = {
    InstanceId = aws_instance.primary_instance.id
  }
}
