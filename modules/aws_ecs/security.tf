resource "aws_security_group" "rds" {
  name        = "${var.deployment_name}-rds-security-group"
  description = "Retool database security group"
  vpc_id      = var.vpc_id

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

resource "aws_security_group" "temporal_aurora" {
  count       = var.workflows_enabled ? 1 : 0
  name        = "${var.deployment_name}-temporal-rds-security-group"
  description = "Retool database security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Retool Temporal ECS Postgres Inbound"
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb" {
  name        = "${var.deployment_name}-alb-security-group"
  description = "Retool load balancer security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_rules
    content {
      description      = ingress.value["description"]
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
    }
  }

  dynamic "egress" {
    for_each = var.alb_egress_rules

    content {
      description      = egress.value["description"]
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      cidr_blocks      = egress.value["cidr_blocks"]
      ipv6_cidr_blocks = egress.value["ipv6_cidr_blocks"]
    }
  }
}

resource "aws_security_group" "containers" {
  name        = "${var.deployment_name}-containers-security-group"
  description = "Retool containers security group"
  vpc_id      = var.vpc_id

  dynamic "egress" {
    for_each = var.container_egress_rules

    content {
      description      = egress.value["description"]
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      cidr_blocks      = egress.value["cidr_blocks"]
      ipv6_cidr_blocks = egress.value["ipv6_cidr_blocks"]
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "variable_rules" {
  for_each = var.container_ingress_rules

  security_group_id = aws_security_group.containers.id
  description       = each.value["description"]
  from_port         = each.value["from_port"]
  to_port           = each.value["to_port"]
  ip_protocol       = each.value["protocol"]
  cidr_ipv4         = each.value["cidr_block"]
  cidr_ipv6         = each.value["ipv6_cidr_block"]
}

resource "aws_vpc_security_group_ingress_rule" "containers_self_ingress" {
  security_group_id = aws_security_group.containers.id

  description = "Allow self-ingress for inter-container communication"
  referenced_security_group_id = aws_security_group.containers.id
  ip_protocol = -1
}