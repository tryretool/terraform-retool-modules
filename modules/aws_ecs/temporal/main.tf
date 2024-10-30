module "temporal_aurora_rds" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "8.5.0"

  name              = "${var.deployment_name}-temporal-rds-instance"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = var.temporal_aurora_engine_version
  storage_encrypted = true

  vpc_id = var.vpc_id

  performance_insights_enabled = var.temporal_aurora_performance_insights_enabled
  monitoring_interval          = 60

  # Create DB Subnet group using var.subnet_ids
  create_db_subnet_group = true
  subnets                = var.subnet_ids

  master_username             = aws_secretsmanager_secret_version.temporal_aurora_username.secret_string
  master_password             = aws_secretsmanager_secret_version.temporal_aurora_password.secret_string
  manage_master_user_password = false

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = var.temporal_aurora_serverless_min_capacity
    max_capacity = var.temporal_aurora_serverless_max_capacity
  }

  security_group_rules = {
    temporal_ingress = {
      source_security_group_id = var.container_sg_id
    }
  }

  instance_class = "db.serverless"
  instances      = var.temporal_aurora_instances

  backup_retention_period = var.temporal_aurora_backup_retention_period
  preferred_backup_window = var.temporal_aurora_preferred_backup_window
}

resource "aws_service_discovery_service" "temporal_frontend_service" {
  name = "temporal"

  dns_config {
    namespace_id = var.private_dns_namespace_id

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

resource "aws_ecs_service" "retool_temporal" {

  for_each = var.temporal_services_config

  name            = "${var.deployment_name}-${each.key}"
  cluster         = var.aws_ecs_cluster_id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.retool_temporal[each.key].arn
  propagate_tags  = var.task_propagate_tags

  # Need to explictly set this in aws_ecs_service to avoid destructive behavior: https://github.com/hashicorp/terraform-provider-aws/issues/22823
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : var.aws_ecs_capacity_provider_name
  }

  dynamic "service_registries" {
    for_each = each.key == "frontend" ? toset([1]) : toset([])
    content {
      registry_arn = aws_service_discovery_service.temporal_frontend_service.arn
    }
  }

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" ? toset([1]) : toset([])

    content {
      subnets = var.subnet_ids
      security_groups = [
        var.container_sg_id
      ]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_task_definition" "retool_temporal" {

  for_each = var.temporal_services_config

  family                   = "${var.deployment_name}-${each.key}"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.launch_type == "FARGATE" ? aws_iam_role.execution_role[0].arn : null
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  cpu                      = var.launch_type == "FARGATE" ? each.value["cpu"] : null
  memory                   = var.launch_type == "FARGATE" ? each.value["memory"] : null
  container_definitions = jsonencode(
    [
      {
        name      = "${var.deployment_name}-${each.key}"
        essential = true
        image     = var.temporal_image
        cpu       = var.launch_type == "EC2" ? each.value["cpu"] : null
        memory    = var.launch_type == "EC2" ? each.value["memory"] : null

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = var.aws_cloudwatch_log_group_id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL_TEMPORAL"
          }
        }

        portMappings = [
          {
            containerPort = each.value["request_port"]
            hostPort      = each.value["request_port"]
            protocol      = "tcp"
          },
          {
            containerPort = each.value["membership_port"]
            hostPort      = each.value["membership_port"]
            protocol      = "tcp"
          }
        ]

        environment = concat(
          local.environment_variables,
          [
            {
              "name"  = "SERVICES"
              "value" = each.key
            },
          ],
          each.key != "frontend" ? [{
            "name" : "PUBLIC_FRONTEND_ADDRESS",
            "value" : "${var.temporal_cluster_config.hostname}.${var.service_discovery_namespace}:${var.temporal_cluster_config.port}"
            }
          ] : []
        )
      }
    ]
  )
}
