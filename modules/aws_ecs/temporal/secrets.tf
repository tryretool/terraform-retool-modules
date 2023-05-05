
resource "random_string" "temporal_aurora_password" {
  length  = var.secret_length
  special = false
}

resource "aws_secretsmanager_secret" "temporal_aurora_password" {
  name        = "${var.deployment_name}-temporal-rds-password"
  description = "This is the password for the Retool Temporal RDS instance"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "temporal_aurora_password" {
  secret_id     = aws_secretsmanager_secret.temporal_aurora_password.id
  secret_string = random_string.temporal_aurora_password.result
}

resource "aws_secretsmanager_secret" "temporal_aurora_username" {
  name        = "${var.deployment_name}-temporal-rds-username"
  description = "This is the username for the Retool Temporal RDS instance"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "temporal_aurora_username" {
  secret_id     = aws_secretsmanager_secret.temporal_aurora_username.id
  secret_string = var.temporal_aurora_username
}