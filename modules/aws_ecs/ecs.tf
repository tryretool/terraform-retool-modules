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
  name_regex  = "^amzn2-ami-ecs-hvm-\\d\\.\\d\\.\\d{8}-x86_64-ebs$"

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

resource "aws_launch_template" "this" {
  count         = var.launch_type == "EC2" ? 1 : 0
  name_prefix   = "${var.deployment_name}-ecs-launch-template-"
  image_id      = data.aws_ami.this.id
  instance_type = var.instance_type # e.g. t2.medium

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.containers.id]
  }

  # This user data represents a collection of “scripts” that will be executed the first time the machine starts.
  # This specific example makes sure the EC2 instance is automatically attached to the ECS cluster that we create earlier
  # and marks the instance as purchased through the Spot pricing
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.deployment_name}-ecs >> /etc/ecs/ecs.config
    EOF
  )
  # If you want to SSH into the instance and manage it directly:
  # 1. Make sure this key exists in the AWS EC2 dashboard
  # 2. Make sure your local SSH agent has it loaded
  # 3. Make sure the EC2 instances are launched within a public subnet (are accessible from the internet)
  key_name = var.ssh_key_name

  # Allow the EC2 instances to access AWS resources on your behalf, using this instance profile and the permissions defined there
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2[0].name
  }

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
  vpc_zone_identifier  = var.private_subnet_ids
  
  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  default_cooldown          = 30
  health_check_grace_period = 30
  health_check_type = "EC2"

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

resource "aws_ecs_capacity_provider" "this" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.deployment_name}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this[0].arn
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
      instance_warmup_period    = 300
    }
  }
}

resource "aws_appautoscaling_target" "retool" {
  count = 1
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${var.deployment_name}-main-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
  depends_on = [aws_ecs_service.retool]
}

resource "aws_appautoscaling_target" "workflows_worker" {
  count = var.workflows_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${var.deployment_name}-workflows-worker-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
  depends_on = [aws_ecs_service.workflows_worker]
}

resource "aws_appautoscaling_target" "workflows_backend" {
  count = var.workflows_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${var.deployment_name}-workflows-backend-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
  depends_on = [aws_ecs_service.workflows_backend]
}

resource "aws_appautoscaling_target" "code_executor" {
  count = var.code_executor_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${var.deployment_name}-code-executor-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
  depends_on = [aws_ecs_service.code_executor]
}

resource "aws_appautoscaling_policy" "retool_cpu" {
  count = 1
  name               = "retool-cpu-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.retool[0].resource_id
  scalable_dimension = aws_appautoscaling_target.retool[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "workflows_worker_cpu" {
  count = var.workflows_enabled ? 1 : 0
  name               = "workflows-worker-cpu-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.workflows_worker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.workflows_worker[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 30
  }
}

resource "aws_appautoscaling_policy" "workflows_backend_cpu" {
  count = var.workflows_enabled ? 1 : 0
  name               = "workflows_backend-cpu-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.workflows_backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.workflows_backend[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "code_executor_cpu" {
  count = var.code_executor_enabled ? 1 : 0
  name               = "code-executor-cpu-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.code_executor[0].resource_id
  scalable_dimension = aws_appautoscaling_target.code_executor[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "retool_memory" {
  count = 1
  name               = "retool-memory-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.retool[0].resource_id
  scalable_dimension = aws_appautoscaling_target.retool[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "workflows_worker_memory" {
  count = var.workflows_enabled ? 1 : 0
  name               = "workflows-worker-memory-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.workflows_worker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.workflows_worker[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "workflows_backend_memory" {
  count = var.workflows_enabled ? 1 : 0
  name               = "workflows_backend-memory-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.workflows_backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.workflows_backend[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "code_executor_memory" {
  count = var.code_executor_enabled ? 1 : 0
  name               = "code-executor-memory-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.code_executor[0].resource_id
  scalable_dimension = aws_appautoscaling_target.code_executor[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Attach an autoscaling policy to the spot cluster to target 70% MemoryReservation on the ECS cluster.
# resource "aws_autoscaling_policy" "this" {
#   count                  = var.launch_type == "EC2" ? 1 : 0
#   name                   = "${var.deployment_name}-ecs-scale-policy"
#   policy_type            = "TargetTrackingScaling"
#   adjustment_type        = "ChangeInCapacity"
#   autoscaling_group_name = aws_autoscaling_group.this[0].name
# 
#   target_tracking_configuration {
#     customized_metric_specification {
#       metric_dimension {
#         name  = "ClusterName"
#         value = "${var.deployment_name}-ecs"
#       }
#       metric_name = "MemoryReservation"
#       namespace   = "AWS/ECS"
#       statistic   = "Average"
#     }
#     target_value = var.autoscaling_memory_reservation_target
#   }
# }
