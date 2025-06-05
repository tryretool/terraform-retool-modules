data "aws_iam_policy_document" "task_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.deployment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_policy.json
  path               = "/"
}

data "aws_iam_policy_document" "service_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "service_role_policy" {
  statement {
    actions = [
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.deployment_name}-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_role_assume_policy.json
  path               = "/"

  inline_policy {
    name   = "${var.deployment_name}-service-policy"
    policy = data.aws_iam_policy_document.service_role_policy.json
  }
}

# Execution Role for Fargate
data "aws_iam_policy_document" "execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution_role" {
  count              = var.launch_type == "FARGATE" ? 1 : 0
  name               = "${var.deployment_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  count      = var.launch_type == "FARGATE" ? 1 : 0
  role       = aws_iam_role.execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_manager_access" {
  count = var.launch_type == "FARGATE" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.temporal_aurora_password.arn,
      aws_secretsmanager_secret.temporal_aurora_username.arn,
    ]
  }
}

resource "aws_iam_policy" "secrets_manager_access" {
  count = var.launch_type == "FARGATE" ? 1 : 0

  name   = "${var.deployment_name}-secrets-manager-access"
  path   = "/"
  policy = data.aws_iam_policy_document.secrets_manager_access[0].json
}

resource "aws_iam_role_policy_attachment" "execution_role_secrets_manager_access" {
  count      = var.launch_type == "FARGATE" ? 1 : 0
  role       = aws_iam_role.execution_role[0].name
  policy_arn = aws_iam_policy.secrets_manager_access[0].arn
}