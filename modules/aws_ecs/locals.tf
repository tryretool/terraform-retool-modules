locals {
  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
    local.temporal_mtls_config,
    [
      {
        name  = "NODE_ENV"
        value = var.node_env
      },
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
        "name": "WORKFLOW_BACKEND_HOST",
        "value": "http://workflow-backend.retoolsvc:3000"
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_NAMESPACE",
        "value": var.temporal_cluster_config.namespace
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_HOST",
        "value": var.temporal_cluster_config.host
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_PORT",
        "value": var.temporal_cluster_config.port
      },
      {
        "name": "WORKFLOW_TEMPORAL_TLS_ENABLED",
        "value": tostring(var.temporal_cluster_config.tls_enabled)
      }
    ]
  )

  temporal_mtls_config = (
    var.temporal_cluster_config.tls_enabled && var.temporal_cluster_config.tls_crt != null && var.temporal_cluster_config.tls_key != null ? 
      [
        {
          "name": "WORKFLOW_TEMPORAL_TLS_CRT",
          "value": var.temporal_cluster_config.tls_crt
        },
        {
          "name": "WORKFLOW_TEMPORAL_TLS_KEY",
          "value": var.temporal_cluster_config.tls_key
        } 
      ] : 
      []
  )
}
