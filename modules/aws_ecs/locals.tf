locals {
  base_environment_variables = [
    {
      name  = "NODE_ENV"
      value = var.node_env
    },
    {
      name  = "IS_ONPREM",
      value = "true"
    },
    {
      name  = "DEPLOYMENT_TEMPLATE_TYPE"
      value = var.launch_type == "FARGATE" ? "aws-ecs-fargate-terraform" : "aws-ecs-ec2-terraform"
    }
  ]

  service_discovery_namespace = var.service_discovery_namespace != "" ? var.service_discovery_namespace : format("%s%s", replace(var.deployment_name, "-", ""), "svc")

  // Use var.ecs_code_executor_image if defined, otherwise fallback to the same tag as var.ecs_retool_image
  ecs_code_executor_image = var.ecs_code_executor_image != "" ? var.ecs_code_executor_image : format("%s:%s", "tryretool/code-executor-service", split(":", var.ecs_retool_image)[1])
  // Use var.ecs_telemetry_image if defined, otherwise fallback to the same tag as var.ecs_retool_image
  ecs_telemetry_image = var.ecs_telemetry_image != "" ? var.ecs_telemetry_image : format("%s:%s", "tryretool/telemetry", split(":", var.ecs_retool_image)[1])
  // Use var.ecs_telemetry_fluentbit_image if defined, otherwise fallback to the same tag as var.ecs_retool_image
  ecs_telemetry_fluentbit_image = var.ecs_telemetry_fluentbit_image != "" ? var.ecs_telemetry_fluentbit_image : format("%s:%s", "tryretool/retool-aws-for-fluent-bit", split(":", var.ecs_retool_image)[1])

  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
    local.base_environment_variables,
    local.temporal_mtls_config,
    var.code_executor_enabled ? [
      {
        name  = "CODE_EXECUTOR_INGRESS_DOMAIN"
        value = format("http://code-executor.%s:3004", local.service_discovery_namespace)
      }
    ] : [],
    var.telemetry_enabled ? [
      {
        name  = "RTEL_ENABLED"
        value = "true"
      },
      {
        name  = "STATSD_HOST"
        value = format("telemetry.%s", local.service_discovery_namespace)
      },
      {
        name  = "STATSD_PORT"
        value = "9125"
      }
    ] : [],
    [
      {
        name  = "FORCE_DEPLOYMENT"
        value = tostring(var.force_deployment)
      },
      {
        name  = "POSTGRES_DB"
        value = "hammerhead_production"
      },
      {
        name  = "POSTGRES_HOST"
        value = aws_db_instance.this.address
      },
      {
        name  = "POSTGRES_SSL_ENABLED"
        value = "true"
      },
      {
        name  = "POSTGRES_PORT"
        value = "5432"
      },
      {
        "name"  = "POSTGRES_USER",
        "value" = var.rds_username
      },
      {
        "name"  = "POSTGRES_PASSWORD",
        "value" = random_string.rds_password.result
      },
      {
        "name" : "JWT_SECRET",
        "value" : random_string.jwt_secret.result
      },
      {
        "name" : "ENCRYPTION_KEY",
        "value" : random_string.encryption_key.result
      },
      {
        "name" : "LICENSE_KEY",
        "value" : var.retool_license_key
      },
      # Workflows-specific
      {
        "name" : "WORKFLOW_BACKEND_HOST",
        "value" : format("http://workflow-backend.%s:3000", local.service_discovery_namespace)
      },
      {
        "name" : "WORKFLOW_TEMPORAL_CLUSTER_NAMESPACE",
        "value" : var.temporal_cluster_config.namespace
      },
      {
        "name" : "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_HOST",
        "value" : format("%s.%s", var.temporal_cluster_config.hostname, local.service_discovery_namespace)
      },
      {
        "name" : "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_PORT",
        "value" : var.temporal_cluster_config.port
      },
      {
        "name" : "WORKFLOW_TEMPORAL_TLS_ENABLED",
        "value" : tostring(var.temporal_cluster_config.tls_enabled)
      }
    ]
  )

  task_log_configuration = (
    var.telemetry_enabled ? {
      # Send logs to CloudWatch in addition to telemetry service:
      logDriver = "awsfirelens"
      options = {
        Name              = "cloudwatch"
        region            = var.aws_region
        log_group_name    = aws_cloudwatch_log_group.this.id
        auto_create_group = "true"
        log_stream_prefix = "SERVICE_RETOOL/"
      }
    } : {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.id
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "SERVICE_RETOOL"
      }
    }
  )

  common_containers = (
    var.telemetry_enabled ? [
      {
        name      = "retool-fluentbit"
        essential = true
        image     = var.ecs_telemetry_fluentbit_image
        cpu       = var.launch_type == "EC2" ? var.ecs_task_resource_map["fluentbit"]["cpu"] : null
        memory    = var.launch_type == "EC2" ? var.ecs_task_resource_map["fluentbit"]["memory"] : null

        firelensConfiguration = {
          type    = "fluentbit"
          options = {
            config-file-type  = "file"
            config-file-value = "/extra.conf"
          }
        }

        logConfiguration = {
          logDriver = "awslogs"
          options   = {
            awslogs-group         = aws_cloudwatch_log_group.this.id
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "SERVICE_RETOOL"
            awslogs-create-group  = "true"
            mode                  = "non-blocking"
            max-buffer-size       = "25m"
          }
        }

        environment = [
          {
            name  = "SERVICE_DISCOVERY_NAMESPACE"
            value = local.service_discovery_namespace
          }
        ]
      }
    ] : []
  )

  temporal_mtls_config = (
    var.temporal_cluster_config.tls_enabled && var.temporal_cluster_config.tls_crt != null && var.temporal_cluster_config.tls_key != null ?
    [
      {
        "name" : "WORKFLOW_TEMPORAL_TLS_CRT",
        "value" : var.temporal_cluster_config.tls_crt
      },
      {
        "name" : "WORKFLOW_TEMPORAL_TLS_KEY",
        "value" : var.temporal_cluster_config.tls_key
      }
    ] :
    []
  )
}
