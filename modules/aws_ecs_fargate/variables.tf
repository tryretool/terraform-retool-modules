variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region. Defaults to `us-east-1`"
}

variable "node_env" {
  type        = string
  default     = "production"
  description = "Value for NODE_ENV variable. Defaults to `production` and should not be set to any other value, regardless of environment."
}

variable "vpc_id" {
  type        = string
  description = "Select a VPC that allows instances access to the Internet."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Select at least two subnets in your selected VPC."
}

variable "deployment_name" {
  type        = string
  description = "Name prefix for created resources. Defaults to `retool`."
  default     = "retool"
}

variable "public_subnet" {
  type        = string
  description = "Public subnet for NAT Gateway."
}

variable "internet_gateway" {
  type        = string
  description = "Internet gateway attached to VPC."
}

variable "ecs_insights_enabled" {
  type        = string
  default     = "enabled"
  description = "Whether or not to enable ECS Container Insights. Defaults to `enabled`"
}

variable "retool_license_key" {
  type        = string
  description = "Retool license key"
  default     = "EXPIRED-LICENSE-KEY-TRIAL"
}

variable "cookie_insecure" {
  type        = bool
  default     = true
  description = "Whether to allow insecure cookies. Should be turned off when serving on HTTPS. Defaults to true."
}

variable "ecs_task_cpu" {
  type        = number
  default     = 1024
  description = "Amount of CPU provisioned for each task. Defaults to 1024."
}

variable "ecs_task_memory" {
  type        = number
  default     = 2048
  description = "Amount of memory provisioned for each task. Defaults to 2048."
}

variable "ecs_task_network_mode" {
  description = "The Docker networking mode to use for the containers in the task"
  type        = string
  default     = "awsvpc"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Number of days to retain logs in CloudWatch. Defaults to 14."
}

variable "rds_username" {
  type        = string
  default     = "retool"
  description = "Master username for the RDS instance. Defaults to Retool."
}

variable "rds_instance_class" {
  type        = string
  default     = "db.m6g.large"
  description = "Instance class for RDS. Defaults to `db.m6g.large`"
}

variable "rds_publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether the RDS instance should be publicly accessible. Defaults to false."
}

variable "rds_performance_insights_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable Performance Insights for RDS. Defaults to true."
}

variable "secret_length" {
  type        = number
  default     = 48
  description = "Length of secrets generated (e.g. ENCRYPTION_KEY, RDS_PASSWORD). Defaults to 48."
}

variable "ecs_service_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = "2"
}

variable "maximum_percent" {
  type        = number
  default     = 250
  description = "Maximum percentage of tasks to run during a deployment. Defaults to 250."
}

variable "minimum_healthy_percent" {
  type        = number
  default     = 50
  description = "Minimum percentage of tasks to run during a deployment. Defaults to 50."
}

variable "ecs_retool_image" {
  type        = string
  description = "Container image for desired Retool version. Defaults to `2.106.2`"
  default     = "tryretool/backend:2.106.2"
}

variable "alb_listener_certificate_arn" {
  description = "Certificate Manager ARN use in ALB listener"
  type        = string
  default     = null
}

variable "alb_ingress_rules" {
  type = list(
    object({
      description      = string
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      ipv6_cidr_blocks = list(string)
    })
  )
  default = [
    {
      description      = "Global HTTP inbound"
      from_port        = "80"
      to_port          = "80"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
  description = "Ingress rules for load balancer"
}

variable "alb_egress_rules" {
  type = list(
    object({
      description      = string
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      ipv6_cidr_blocks = list(string)
    })
  )
  default = [
    {
      description      = "Global outbound"
      from_port        = "0"
      to_port          = "0"
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
  description = "Egress rules for load balancer"
}

variable "alb_idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle. Defaults to 60."
}

variable "additional_env_vars" {
  type        = list(map(string))
  default     = []
  description = "Additional environment variables (e.g. BASE_DOMAIN)"
}

variable "force_deployment" {
  type        = string
  default     = false
  description = "Used to force the deployment even when the image and parameters are otherwised unchanged. Defaults to false."
}

variable "alb_listener_ssl_policy" {
  description = "retool_alb_listener_ssl_policy"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "aws_lb_listener_protocol" {
  description = "AWS ALB listening protocol e.g HTTP, HTTPS etc"
  type        = string
  default     = "HTTP"
}

variable "aws_alb_target_group_protocol" {
  description = "Protocol ALB should use to talk with target group e.g HTTP, HTTPS etc"
  type        = string
  default     = "HTTP"
}

variable "retool_alb_ingress_port" {
  description = "Retool ALB ingress port"
  type        = number
  default     = "3000"
}

variable "retool_task_container_port" {
  description = "Retool task listening port"
  type        = number
  default     = "3000"
}

variable "retool_task_container_name" {
  description = "Name of Retool task"
  type        = string
  default     = "retool"
}

variable "retool_task_container_cookie_insecure" {
  description = "Allow cookies to be insecure e.g. not using Retool over https"
  type        = bool
  default     = true
}

variable "postgresql_ssl_enabled" {
  description = "Enable or disable postgresql SSL"
  type        = bool
  default     = true
}

variable "postgresql_db_port" {
  description = "Postgresql RDS listening port"
  type        = number
  default     = "5432"
}

variable "retool_ecs_tasks_logdriver" {
  description = "Send log information to CloudWatch Logs"
  type        = string
  default     = "awslogs"
}

variable "retool_ecs_tasks_log_prefix" {
  description = "Associate a log stream with the specified prefix, the container name, and the ID of the Amazon ECS task that the container belongs to"
  type        = string
  default     = "SERVICE_RETOOL"
}
