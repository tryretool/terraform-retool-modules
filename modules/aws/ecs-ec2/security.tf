resource "aws_security_group" "rds" {
  name        = "${var.deployment_name}-rds-security-group"
  description = "Retool database security group"

  ingress {
    description = "Retool ECS Postgres Inbound"
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound - modify if necessary
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.deployment_name}-alb-security-group"
  description = "Retool load balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Global HTTP Inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound - modify if necessary
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.deployment_name}-ec2-security-group"
  description = "Retool EC2 security group"
  vpc_id      = var.vpc_id

  # Allow all inbound - modify if necessary
  ingress {
    description = "Global HTTP Inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Global HTTPS Inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound - modify if necessary
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    ipv6_cidr_blocks = ["::/0"]
  }
}