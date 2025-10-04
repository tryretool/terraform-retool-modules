resource "aws_security_group" "rds" {
  name        = "${var.deployment_name}-rds-security-group"
  description = "Retool database security group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress_from_ecs_tasks" {
  security_group_id = aws_security_group.rds.id

  description                  = "Postgres ingress from ECS tasks"
  from_port                    = "5432"
  to_port                      = "5432"
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_security_group" "alb" {
  name        = "${var.deployment_name}-alb-security-group"
  description = "Retool load balancer security group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  for_each = var.alb_ingress_rules_map

  security_group_id = aws_security_group.alb.id

  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_to_ecs_tasks" {
  security_group_id = aws_security_group.alb.id

  description                  = "HTTP to ECS tasks"
  from_port                    = var.retool_task_container_port
  to_port                      = var.retool_task_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.deployment_name}-ecs-tasks-security-group"
  description = "Retool ECS tasks security group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_ingress_from_alb" {
  security_group_id = aws_security_group.ecs_tasks.id

  description                  = "HTTP from ALB"
  from_port                    = var.retool_task_container_port
  to_port                      = var.retool_task_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_to_rds" {
  security_group_id = aws_security_group.ecs_tasks.id

  description                  = "Postgres egress to RDS"
  from_port                    = "5432"
  to_port                      = "5432"
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_extra" {
  for_each = var.ecs_tasks_extra_egress_rules_map

  security_group_id = aws_security_group.ecs_tasks.id

  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
}
