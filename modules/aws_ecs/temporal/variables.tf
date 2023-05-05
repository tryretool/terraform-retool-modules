# namescape: temporal namespace to use for Retool Workflows. We recommend this is only used by Retool.
# host: hostname for Temporal Frontend service
# port: port for Temporal Frontend service
# tls_enabled: Whether to use tls when connecting to Temporal Frontend. For mTLS, configure tls_crt and tls_key.
# tls_crt: For mTLS only. Base64 encoded string of public tls certificate
# tls_key: For mTLS only. Base64 encoded string of private tls key
variable "temporal_cluster_config" {
  type = object({
      namespace   = string
      host        = string
      port        = string
      tls_enabled = bool
      tls_crt     = optional(string)
      tls_key     = optional(string)
    })

    default = {
      namespace   = "workflows"
      host        = "temporal.retoolsvc"
      port        = "7233"
      tls_enabled = false
    }
}

variable "temporal_services_config" {
  type = map(object({
      request_port = number
      membership_port = number
      cpu = number
      memory = number
  }))

  default = {
    frontend: {
      request_port = 7233,
      membership_port = 6933
      cpu = 512
      memory = 1024
    },
    history: {
      request_port = 7234,
      membership_port = 6934
      cpu = 512
      memory = 2048
    },
    matching: {
      request_port = 7235,
      membership_port = 6935
      cpu = 512
      memory = 1024
    },
    worker: {
      request_port = 7239,
      membership_port = 6939
      cpu = 512
      memory = 1024
    }
  }
}

variable "deployment_name" {
    type      = string
    default   = "retool-temporal"
    description = "Name for Temporal Cluster deployment. Defaults to retool-temporal"
}

variable "launch_type" {
  type        = string
  default     = "FARGATE"

  validation {
    condition = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type must be either \"FARGATE\" or \"EC2\""
  }
}

variable "temporal_aurora_username" {
  type        = string
  default     = "retool"
  description = "Master username for the Temporal Aurora instance. Defaults to retool."
}

variable "temporal_aurora_publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether the Temporal Aurora instance should be publicly accessible. Defaults to false."
}

variable "temporal_aurora_performance_insights_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable Performance Insights for Temporal Aurora. Defaults to true."
}

variable "temporal_aurora_performance_insights_retention_period" {
  type        = number
  default     = 14
  description = "The time in days to retain Performance Insights for Temporal Aurora. Defaults to 14."
}

variable "additional_temporal_env_vars" {
  type        = list(map(string))
  default     = []
  description = "Additional environment variables for Temporal containers (e.g. DYNAMIC_CONFIG_PATH)"
}

variable "private_dns_namespace_id" {
  type        = string
  description = "ID for private DNS namespace to use for Temporal Frontend service"
}

variable "temporal_image" {
  type = string
  default = "tryretool/one-offs:retool-temporal-1.1.2"
  description = "Docker image to use for Temporal cluster."
}

variable "secret_length" {
  type        = number
  default     = 48
  description = "Length of secrets generated (e.g. ENCRYPTION_KEY, RDS_PASSWORD). Defaults to 48."
}

variable "vpc_id" {
  type        = string
  description = "Select a VPC that allows instances access to the Internet."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Select at two subnets in your selected VPC."
}

variable "container_sg_id" {
  type = string
  description = "ID for security group to use for ECS service"
}

variable "aws_ecs_capacity_provider_name" {
  type = string
  description = "Name for ECS capacity provider for EC2"
}

variable "additional_env_vars" {
  type        = list(map(string))
  default     = []
  description = "Additional environment variables (e.g. BASE_DOMAIN)"
}

variable "aws_ecs_cluster_id" {
  type = string
  description = "ID for ECS cluster to deploy Temporal to."
}

variable "aws_cloudwatch_log_group_id" {
  type        = string
  description = "ID for AWS CloudWatch log group"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region. Defaults to `us-east-1`"
}


