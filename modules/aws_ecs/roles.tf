data "aws_iam_policy_document" "task_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_role_policy" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.deployment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_policy.json
  path               = "/"

  inline_policy {
    name   = "${var.deployment_name}-task-policy"
    policy = data.aws_iam_policy_document.task_role_policy.json
  }
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
  policy_arn = "arn:${var.iam_partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for EC2 instances
resource "aws_iam_instance_profile" "ec2" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.deployment_name}-ec2-instance-profile"
  role  = aws_iam_role.ec2[0].name
}

resource "aws_iam_role" "ec2" {
  count              = var.launch_type == "EC2" ? 1 : 0
  name               = "${var.deployment_name}-ec2-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_policy.json
  path               = "/"

  inline_policy {
    name   = "${var.deployment_name}-ec2-policy"
    policy = data.aws_iam_policy_document.ec2_policy.json
  }
}

data "aws_iam_policy_document" "ec2_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
