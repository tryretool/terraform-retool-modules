resource "random_string" "rds_password" {
  length  = var.secret_length
  special = false
}

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${var.deployment_name}-rds-password"
  description = "This is the password for the Retool RDS instance"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_string.rds_password.result
}

resource "aws_secretsmanager_secret" "rds_username" {
  name        = "${var.deployment_name}-rds-username"
  description = "This is the username for the Retool RDS instance"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_username" {
  secret_id     = aws_secretsmanager_secret.rds_username.id
  secret_string = var.rds_username
}

resource "random_string" "jwt_secret" {
  length  = var.secret_length
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.deployment_name}-jwt-secret"
  description = "This is the secret for Retool JWTs"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_string.jwt_secret.result
}


resource "random_string" "encryption_key" {
  length  = var.secret_length
  special = false
}

resource "aws_secretsmanager_secret" "encryption_key" {
  name        = "${var.deployment_name}-encryption-key"
  description = "This is the secret for encrypting credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "encryption_key" {
  secret_id     = aws_secretsmanager_secret.encryption_key.id
  secret_string = random_string.encryption_key.result
}
