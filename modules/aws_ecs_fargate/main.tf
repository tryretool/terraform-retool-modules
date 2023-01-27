terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "this" {
  name = "${var.deployment_name}-ecs"

  setting {
    name  = "containerInsights"
    value = var.ecs_insights_enabled
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.deployment_name}-ecs-log-group"
  retention_in_days = var.log_retention_in_days
}

resource "aws_db_instance" "this" {
  identifier                    = "${var.deployment_name}-rds-instance"
  allocated_storage            = 80
  instance_class               = var.rds_instance_class
  engine                       = "postgres"
  engine_version               = "13.7"
  db_name                      = "hammerhead_production"
  username                     = aws_secretsmanager_secret_version.rds_username.secret_string
  password                     = aws_secretsmanager_secret_version.rds_password.secret_string
  port                         = 5432
  publicly_accessible          = var.rds_publicly_accessible
  vpc_security_group_ids       = [aws_security_group.rds.id]
  performance_insights_enabled = var.rds_performance_insights_enabled
  
  skip_final_snapshot          = true
  apply_immediately           = true
}

resource "aws_ecs_service" "retool" {
  name                               = "${var.deployment_name}-main-service"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.retool.arn
  desired_count                      = var.ecs_service_count
  deployment_maximum_percent         = var.maximum_percent
  deployment_minimum_healthy_percent = var.minimum_healthy_percent
  launch_type                        = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "retool"
    container_port   = 3000
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.alb.id]
  }
}

resource "aws_ecs_task_definition" "retool" {
    family                   = "${var.deployment_name}-backend"
    requires_compatibilities = ["FARGATE"]
    network_mode             = var.ecs_task_network_mode
    cpu                      = var.ecs_task_cpu
    memory                   = var.ecs_task_memory
    task_role_arn            = aws_iam_role.task_role.arn
    execution_role_arn       = aws_iam_role.execution_role.arn
    container_definitions    = <<TASK_DEFINITION
[
  {
    "command": ["./docker_scripts/start_api.sh"],
    "environment": [
      {"name": "NODE_ENV", "value": "${var.node_env}"},
      {"name": "SERVICE_TYPE", "value": "MAIN_BACKEND,DB_CONNECTOR"},
      {"name": "FORCE_DEPLOYMENT", "value": "${var.force_deployment}"},
      {"name": "POSTGRES_DB", "value": "hammerhead_production"},
      {"name": "POSTGRES_HOST", "value": "${aws_db_instance.this.address}"},
      {"name": "POSTGRES_SSL_ENABLED", "value": "${var.postgresql_ssl_enabled}"},
      {"name": "POSTGRES_PORT", "value": "${var.postgresql_db_port}"},
      {"name": "POSTGRES_USER", "value": "${aws_secretsmanager_secret_version.rds_username.secret_string}"},
      {"name": "POSTGRES_PASSWORD", "value": "${aws_secretsmanager_secret_version.rds_password.secret_string}"},
      {"name": "JWT_SECRET", "value": "${random_string.jwt_secret.result}"},
      {"name": "ENCRYPTION_KEY", "value": "${random_string.encryption_key.result}"},
      {"name": "LICENSE_KEY", "value": "${var.retool_license_key}"},
      {"name": "COOKIE_INSECURE", "value": "${var.cookie_insecure}"}
    ],
    "logConfiguration": {
      "logDriver": "${var.retool_ecs_tasks_logdriver}",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.this.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.retool_ecs_tasks_log_prefix}"
      }
    },
    "essential": true,
    "image": "${local.retool_image}",
    "name": "${var.retool_task_container_name}",
    "portMappings": [
      {
        "containerPort": ${var.retool_task_container_port}
      }
    ]
  }
]
TASK_DEFINITION
}

resource "aws_ecs_service" "jobs_runner" {
  name            = "${var.deployment_name}-jobs-runner-service"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_jobs_runner.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.alb.id]
  }
}

resource "aws_ecs_task_definition" "retool_jobs_runner" {
    family                   = "${var.deployment_name}-jobs-runner"
    requires_compatibilities = ["FARGATE"]
    network_mode             = var.ecs_task_network_mode
    cpu                      = var.ecs_task_cpu
    memory                   = var.ecs_task_memory
    task_role_arn            = aws_iam_role.task_role.arn
    execution_role_arn       = aws_iam_role.execution_role.arn
    container_definitions    = <<TASK_DEFINITION
[
  {
    "command": ["./docker_scripts/start_api.sh"],
    "environment": [
      {"name": "NODE_ENV", "value": "${var.node_env}"},
      {"name": "SERVICE_TYPE", "value": "JOBS_RUNNER"},
      {"name": "FORCE_DEPLOYMENT", "value": "${var.force_deployment}"},
      {"name": "POSTGRES_DB", "value": "hammerhead_production"},
      {"name": "POSTGRES_HOST", "value": "${aws_db_instance.this.address}"},
      {"name": "POSTGRES_SSL_ENABLED", "value": "${var.postgresql_ssl_enabled}"},
      {"name": "POSTGRES_PORT", "value": "${var.postgresql_db_port}"},
      {"name": "POSTGRES_USER", "value": "${aws_secretsmanager_secret_version.rds_username.secret_string}"},
      {"name": "POSTGRES_PASSWORD", "value": "${aws_secretsmanager_secret_version.rds_password.secret_string}"},
      {"name": "JWT_SECRET", "value": "${random_string.jwt_secret.result}"},
      {"name": "ENCRYPTION_KEY", "value": "${random_string.encryption_key.result}"},
      {"name": "LICENSE_KEY", "value": "${var.retool_license_key}"},
      {"name": "COOKIE_INSECURE", "value": "${var.cookie_insecure}"}
    ],
    "logConfiguration": {
      "logDriver": "${var.retool_ecs_tasks_logdriver}",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.this.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.retool_ecs_tasks_log_prefix}"
      }
    },
    "essential": true,
    "image": "${local.retool_image}",
    "name": "${var.retool_task_container_name}",
    "portMappings": [
      {
        "containerPort": ${var.retool_task_container_port}
      }
    ]
  }
]
TASK_DEFINITION
}

# resource "aws_iam_role" "retool_service_role" {
#   name = "${var.deployment_name}-service-role"
#   path = "/"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs.amazonaws.com"
#         }
#       }
#     ]
#   })

#   inline_policy {
#     name = "${var.deployment_name}-env-service-policy"

#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Action = [
#             "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
#             "elasticloadbalancing:DeregisterTargets",
#             "elasticloadbalancing:Describe*",
#             "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
#             "elasticloadbalancing:RegisterTargets",
#             "ec2:Describe*",
#             "ec2:AuthorizeSecurityGroupIngress"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#       }]
#     })
#   }
# }

# resource "aws_iam_role" "retool_task_role" {
#   name = "${var.deployment_name}-task-role"
#   path = "/"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }
