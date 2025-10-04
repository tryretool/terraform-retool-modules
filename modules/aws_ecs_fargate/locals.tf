locals {
  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
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
      }
    ]
  )

  stack_name                          = "${var.deployment_name}"
  database_name                       =  aws_db_instance.this.db_name
  db_subnet_group_name                = "${var.deployment_name}-subnet-group"
  retool_image                        = "${var.ecs_retool_image}"
  retool_alb_ingress_port             = var.alb_listener_certificate_arn != null ? "443" : var.retool_alb_ingress_port
  retool_alb_listener_protocol        = var.alb_listener_certificate_arn != null ? "HTTPS" : var.aws_lb_listener_protocol
  retool_alb_listener_ssl_policy      = var.alb_listener_certificate_arn != null ? var.alb_listener_ssl_policy : null
  retool_alb_listener_certificate_arn = var.alb_listener_certificate_arn
  retool_url_port                     = local.retool_alb_ingress_port != "443" ? ":${local.retool_alb_ingress_port}" : ""

  retool_jwt_secret = {
    password = aws_secretsmanager_secret_version.jwt_secret
  }
  retool_encryption_key_secret = {
    password = random_string.encryption_key.result
  }
  retool_rds_secret = {
    username = "retool"
    password = aws_secretsmanager_secret.rds_password
  }
}
