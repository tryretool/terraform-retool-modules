terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.deployment_name}-ecs-log-group"
  retention_in_days = var.log_retention_in_days
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.deployment_name}-retool"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier                   = "${var.deployment_name}-rds-instance"
  allocated_storage            = var.rds_allocated_storage
  instance_class               = var.rds_instance_class
  ca_cert_identifier           = var.rds_ca_cert_identifier
  engine                       = "postgres"
  engine_version               = var.rds_instance_engine_version
  auto_minor_version_upgrade   = var.rds_instance_auto_minor_version_upgrade
  db_name                      = "hammerhead_production"
  username                     = aws_secretsmanager_secret_version.rds_username.secret_string
  password                     = aws_secretsmanager_secret_version.rds_password.secret_string
  port                         = 5432
  publicly_accessible          = var.rds_publicly_accessible
  vpc_security_group_ids       = [aws_security_group.rds.id]
  db_subnet_group_name         = aws_db_subnet_group.this.id
  performance_insights_enabled = var.rds_performance_insights_enabled
  storage_encrypted            = var.rds_instance_storage_encrypted
  storage_type                 = var.rds_storage_type
  storage_throughput           = var.rds_storage_throughput
  iops                         = var.rds_iops
  multi_az                     = var.rds_multi_az

  skip_final_snapshot = true
  apply_immediately   = true
}

resource "aws_ecs_service" "retool" {
  name                               = "${var.deployment_name}-main-service"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.retool.arn
  desired_count                      = var.min_instance_count - 1
  deployment_maximum_percent         = var.maximum_percent
  deployment_minimum_healthy_percent = var.minimum_healthy_percent
  iam_role                           = var.launch_type == "EC2" ? aws_iam_role.service_role.arn : null
  propagate_tags                     = var.task_propagate_tags

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "retool"
    container_port   = 3000
  }

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])


    content {
      subnets = var.private_subnet_ids
      security_groups = [
        aws_security_group.containers.id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_service" "jobs_runner" {
  name            = "${var.deployment_name}-jobs-runner-service"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_jobs_runner.arn
  propagate_tags  = var.task_propagate_tags

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }

  dynamic "network_configuration" {

    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])

    content {
      subnets = var.private_subnet_ids
      security_groups = [
        aws_security_group.containers.id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_service" "workflows_backend" {
  count           = var.workflows_enabled ? 1 : 0
  name            = "${var.deployment_name}-workflows-backend-service"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_workflows_backend[0].arn
  propagate_tags  = var.task_propagate_tags

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }

  service_registries {
    registry_arn = aws_service_discovery_service.retool_workflow_backend_service[0].arn
  }
  dynamic "network_configuration" {

    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])

    content {
      subnets = var.private_subnet_ids
      security_groups = [
        aws_security_group.containers.id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_service" "workflows_worker" {
  count           = var.workflows_enabled ? 1 : 0
  name            = "${var.deployment_name}-workflows-worker-service"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_workflows_worker[0].arn
  propagate_tags  = var.task_propagate_tags

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }
  dynamic "network_configuration" {

    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])

    content {
      subnets = var.private_subnet_ids
      security_groups = [
        aws_security_group.containers.id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_service" "code_executor" {
  count           = var.code_executor_enabled ? 1 : 0
  name            = "${var.deployment_name}-code-executor-service"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_code_executor[0].arn

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }

  service_registries {
    registry_arn = aws_service_discovery_service.retool_code_executor_service[0].arn
  }
  dynamic "network_configuration" {

    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])

    content {
      subnets = var.private_subnet_ids
      security_groups = [
        aws_security_group.containers.id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_task_definition" "retool_jobs_runner" {
  family                   = "retool-jobs-runner"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["jobs_runner"]["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["jobs_runner"]["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "retool-jobs-runner"
        essential = true
        image     = var.ecs_retool_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["jobs_runner"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["jobs_runner"]["memory"] : null
        command = [
          "./docker_scripts/start_api.sh"
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
          }
        }

        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.environment_variables,
          [
            {
              name  = "SERVICE_TYPE"
              value = "JOBS_RUNNER"
            }
          ]
        )
      }
    ]
  )
}
resource "aws_ecs_task_definition" "retool" {
  family                   = "retool"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["main"]["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["main"]["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "retool"
        essential = true
        image     = var.ecs_retool_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["main"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["main"]["memory"] : null
        command = [
          "./docker_scripts/start_api.sh"
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
          }
        }

        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.environment_variables,
          [
            {
              name  = "SERVICE_TYPE"
              value = "MAIN_BACKEND,DB_CONNECTOR,DB_SSH_CONNECTOR"
            },
            {
              "name"  = "COOKIE_INSECURE",
              "value" = tostring(var.cookie_insecure)
            }
          ]
        )
      }
    ]
  )
}

resource "aws_ecs_task_definition" "retool_workflows_backend" {
  count                    = var.workflows_enabled ? 1 : 0
  family                   = "retool-workflows-backend"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["workflows_backend"]["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["workflows_backend"]["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "retool-workflows-backend"
        essential = true
        image     = var.ecs_retool_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["workflows_backend"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["workflows_backend"]["memory"] : null
        command = [
          "./docker_scripts/start_api.sh"
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
          }
        }

        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.environment_variables,
          [
            {
              name  = "SERVICE_TYPE"
              value = "WORKFLOW_BACKEND,DB_CONNECTOR,DB_SSH_CONNECTOR"
            },
            {
              "name"  = "COOKIE_INSECURE",
              "value" = tostring(var.cookie_insecure)
            }
          ]
        )
      }
    ]
  )
}
resource "aws_ecs_task_definition" "retool_workflows_worker" {
  count                    = var.workflows_enabled ? 1 : 0
  family                   = "retool-workflows-worker"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["workflows_worker"]["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["workflows_worker"]["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "retool-workflows-worker"
        essential = true
        image     = var.ecs_retool_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["workflows_worker"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["workflows_worker"]["memory"] : null
        command = [
          "./docker_scripts/start_api.sh"
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
          }
        }

        health_check = {
          command = ["CMD-SHELL", "curl http://localhost/api/checkHealth:3005 || exit 1"]
        }

        portMappings = [
          {
            containerPort = 3005
            hostPort      = 3005
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.environment_variables,
          [
            {
              name  = "SERVICE_TYPE"
              value = "WORKFLOW_TEMPORAL_WORKER"
            },
            {
              "name"  = "COOKIE_INSECURE",
              "value" = tostring(var.cookie_insecure)
            }
          ]
        )
      }
    ]
  )
}

resource "aws_ecs_task_definition" "retool_code_executor" {
  count                    = var.code_executor_enabled ? 1 : 0
  family                   = "retool-code-executor"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["code_executor"]["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? var.ecs_task_resource_map["code_executor"]["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "retool-code-executor"
        essential = true
        image     = local.ecs_code_executor_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["code_executor"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["code_executor"]["memory"] : null
        user      = var.launch_type == "FARGATE" ? "1001:1001" : null
        command = [
          "./start.sh"
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
          }
        }

        health_check = {
          command = ["CMD-SHELL", "curl http://localhost/api/checkHealth:3004 || exit 1"]
        }

        portMappings = [
          {
            containerPort = 3004
            hostPort      = 3004
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.base_environment_variables,
          # https://docs.retool.com/reference/environment-variables/code-executor#container_unprivileged_mode
          var.launch_type == "FARGATE" ? [
            {
              name  = "CONTAINER_UNPRIVILEGED_MODE"
              value = "true"
            }
          ] : []
        )
      }
    ]
  )
}

resource "aws_service_discovery_private_dns_namespace" "retool_namespace" {
  count       = (var.code_executor_enabled || var.workflows_enabled) ? 1 : 0
  name        = local.service_discovery_namespace
  description = "Service Discovery namespace for Retool deployment"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "retool_workflow_backend_service" {
  count = var.workflows_enabled ? 1 : 0
  name  = "workflow-backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.retool_namespace[0].id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "retool_code_executor_service" {
  count = var.code_executor_enabled ? 1 : 0
  name  = "code-executor"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.retool_namespace[0].id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

module "temporal" {
  count                       = var.workflows_enabled && !var.use_existing_temporal_cluster ? 1 : 0
  source                      = "./temporal"
  deployment_name             = "${var.deployment_name}-temporal"
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.private_subnet_ids
  private_dns_namespace_id    = aws_service_discovery_private_dns_namespace.retool_namespace[0].id
  aws_cloudwatch_log_group_id = aws_cloudwatch_log_group.this.id
  temporal_services_config = {
    frontend = {
      request_port    = 7233,
      membership_port = 6933
      cpu             = var.temporal_ecs_task_resource_map["frontend"]["cpu"]
      memory          = var.temporal_ecs_task_resource_map["frontend"]["memory"]
    },
    history = {
      request_port    = 7234,
      membership_port = 6934
      cpu             = var.temporal_ecs_task_resource_map["history"]["cpu"]
      memory          = var.temporal_ecs_task_resource_map["history"]["memory"]
    },
    matching = {
      request_port    = 7235,
      membership_port = 6935
      cpu             = var.temporal_ecs_task_resource_map["matching"]["cpu"]
      memory          = var.temporal_ecs_task_resource_map["matching"]["memory"]
    },
    worker = {
      request_port    = 7239,
      membership_port = 6939
      cpu             = var.temporal_ecs_task_resource_map["worker"]["cpu"]
      memory          = var.temporal_ecs_task_resource_map["worker"]["memory"]
    }
  }
  temporal_aurora_performance_insights_enabled = var.temporal_aurora_performance_insights_enabled
  temporal_aurora_engine_version               = var.temporal_aurora_engine_version
  temporal_aurora_serverless_min_capacity      = var.temporal_aurora_serverless_min_capacity
  temporal_aurora_serverless_max_capacity      = var.temporal_aurora_serverless_max_capacity
  temporal_aurora_backup_retention_period      = var.temporal_aurora_backup_retention_period
  temporal_aurora_preferred_backup_window      = var.temporal_aurora_preferred_backup_window
  temporal_aurora_instances                    = var.temporal_aurora_instances
  aws_region                                   = var.aws_region
  aws_ecs_cluster_id                           = aws_ecs_cluster.this.id
  launch_type                                  = var.launch_type
  container_sg_id                              = aws_security_group.containers.id
  aws_ecs_capacity_provider_name               = var.launch_type == "EC2" ? aws_ecs_capacity_provider.this[0].name : null
  task_propagate_tags                          = var.task_propagate_tags
  service_discovery_namespace                  = local.service_discovery_namespace
}
