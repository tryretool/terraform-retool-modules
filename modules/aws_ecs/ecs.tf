resource "aws_ecs_cluster" "this" {
  name = "${var.deployment_name}-ecs"

  setting {
    name  = "containerInsights"
    value = var.ecs_insights_enabled
  }
}

# Fargate capacity provider
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = var.launch_type == "FARGATE" ? ["FARGATE"] : [aws_ecs_capacity_provider.this[0].name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.launch_type == "FARGATE" ? "FARGATE" : aws_ecs_capacity_provider.this[0].name
  }
}

# Required setup for EC2 instances (if not using Fargate)
data "aws_ami" "this" {
  most_recent = true # get the latest version
  name_regex = "^amzn2-ami-ecs-hvm-\\d\\.\\d\\.\\d{8}-x86_64-ebs$"

  filter {
    name = "virtualization-type"
    values = [
      "hvm"
    ]
  }

  owners = [
    "amazon" # only official images
  ]
}

resource "aws_launch_configuration" "this" {
  count         = var.launch_type == "EC2" ? 1 : 0
  name_prefix   = "${var.deployment_name}-ecs-launch-configuration-"
  image_id      = data.aws_ami.this.id
  instance_type = var.instance_type # e.g. t2.medium

  enable_monitoring           = true
  associate_public_ip_address = true

  # This user data represents a collection of “scripts” that will be executed the first time the machine starts.
  # This specific example makes sure the EC2 instance is automatically attached to the ECS cluster that we create earlier
  # and marks the instance as purchased through the Spot pricing
  user_data = <<-EOF
  #!/bin/bash
  echo ECS_CLUSTER=${var.deployment_name}-ecs >> /etc/ecs/ecs.config
  EOF

  # We’ll see security groups later
  security_groups = [
    aws_security_group.containers.id
  ]

  # If you want to SSH into the instance and manage it directly:
  # 1. Make sure this key exists in the AWS EC2 dashboard
  # 2. Make sure your local SSH agent has it loaded
  # 3. Make sure the EC2 instances are launched within a public subnet (are accessible from the internet)
  key_name = var.ssh_key_name

  # Allow the EC2 instances to access AWS resources on your behalf, using this instance profile and the permissions defined there
  iam_instance_profile = aws_iam_instance_profile.ec2[0].arn
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  count                = var.launch_type == "EC2" ? 1 : 0
  name                 = "${var.deployment_name}-autoscaling-group"
  max_size             = var.max_instance_count
  min_size             = var.min_instance_count
  desired_capacity     = var.min_instance_count
  vpc_zone_identifier  = var.subnet_ids
  launch_configuration = aws_launch_configuration.this[0].name

  default_cooldown          = 30
  health_check_grace_period = 30

  termination_policies = [
    "OldestInstance"
  ]

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster"
    value               = "${var.deployment_name}-ecs"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.deployment_name}-ec2-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Attach an autoscaling policy to the spot cluster to target 70% MemoryReservation on the ECS cluster.
resource "aws_autoscaling_policy" "this" {
  count                  = var.launch_type == "EC2" ? 1 : 0
  name                   = "${var.deployment_name}-ecs-scale-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.this[0].name

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = "${var.deployment_name}-ecs"
      }
      metric_name = "MemoryReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }
    target_value = var.autoscaling_memory_reservation_target
  }
}

resource "aws_ecs_capacity_provider" "this" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.deployment_name}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this[0].arn
  }
}