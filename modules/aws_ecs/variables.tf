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

variable "private_subnet_ids" {
  type        = list(string)
  description = "Select at two subnets in your selected VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Select at least two subnets in your selected VPC."
}


variable "ssh_key_name" {
  type        = string
  description = "SSH key name for accessing EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "ECS cluster instance type. Defaults to `t3.xlarge`"
  default     = "t3.xlarge"
}

variable "max_instance_count" {
  type        = number
  description = "Max number of EC2 instances. Defaults to 10."
  default     = 10
}

variable "min_instance_count" {
  type        = number
  description = "Min/desired number of EC2 instances. Defaults to 4."
  default     = 3
}

variable "deployment_name" {
  type        = string
  description = "Name prefix for created resources. Defaults to `retool`."
  default     = "retool"
}

variable "service_discovery_namespace" {
  type        = string
  description = "Service discovery namespace DNS name. Default is based on deployment name (see locals.tf)."
  default     = ""
}

variable "task_propagate_tags" {
  type        = string
  description = "Which resource to propagate tags from for ECS service tasks. Defaults to `TASK_DEFINITION`"
  default     = "TASK_DEFINITION"
}

variable "retool_license_key" {
  type        = string
  description = "Retool license key"
  default     = "EXPIRED-LICENSE-KEY-TRIAL"
}

variable "ecs_retool_image" {
  type        = string
  description = "Container image for desired Retool version. Defaults to `3.114.2-stable`"
  default     = "tryretool/backend:3.114.2-stable"
}

variable "ecs_code_executor_image" {
  type        = string
  description = "Container image for desired code_executor version. Defaults to `3.114.2-stable`"
  default     = "tryretool/code-executor-service:3.114.2-stable"
}

variable "ecs_telemetry_image" {
  type        = string
  description = "Container image for desired telemetry sidecar version. Defaults to same version as ecs_retool_image (see locals.tf)."
  default     = ""
}

variable "ecs_telemetry_fluentbit_image" {
  type        = string
  description = "Container image for desired fluent-bit sidecar version. Defaults to same version as ecs_retool_image (see locals.tf)."
  default     = "tryretool/retool-aws-for-fluent-bit:3.120.0-edge"
}

variable "ecs_task_resource_map" {
  type = map(object({
    cpu    = number
    memory = number
  }))
  default = {
    main = {
      cpu    = 2048
      memory = 4096
    },
    jobs_runner = {
      cpu    = 1024
      memory = 2048
    },
    workflows_backend = {
      cpu    = 2048
      memory = 4096
    }
    workflows_worker = {
      cpu    = 2048
      memory = 4096
    }
    code_executor = {
      cpu    = 2048
      memory = 4096
    }
    telemetry = {
      cpu    = 1024
      memory = 2048
    }
    fluentbit = {
      cpu    = 512
      memory = 1024
    }
  }
  description = "Amount of CPU and Memory provisioned for each task."
}

variable "temporal_ecs_task_resource_map" {
  type = map(object({
    cpu    = number
    memory = number
  }))
  default = {
    frontend = {
      cpu    = 512
      memory = 1024
    },
    history = {
      cpu    = 512
      memory = 2048
    },
    matching = {
      cpu    = 512
      memory = 1024
    },
    worker = {
      cpu    = 512
      memory = 1024
    }
  }
  description = "Amount of CPU and Memory provisioned for each Temporal task."
}

variable "force_deployment" {
  type        = string
  default     = false
  description = "Used to force the deployment even when the image and parameters are otherwised unchanged. Defaults to false."
}

variable "ecs_insights_enabled" {
  type        = string
  default     = "enabled"
  description = "Whether or not to enable ECS Container Insights. Defaults to `enabled`"
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

variable "rds_instance_engine_version" {
  type        = string
  default     = "15.10"
  description = "Version of the Postgres RDS instance. Defaults to 15.10"
}

variable "rds_instance_auto_minor_version_upgrade" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade the minor version of the Postgres RDS instance. Defaults to true."
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

variable "rds_performance_insights_retention_period" {
  type        = number
  default     = 14
  description = "The time in days to retain Performance Insights for RDS. Defaults to 14."
}

variable "rds_ca_cert_identifier" {
  type        = string
  default     = "rds-ca-rsa2048-g1"
  description = "The identifier of the CA certificate for the DB instance"
}

variable "rds_instance_storage_encrypted" {
  type        = bool
  default     = false
  description = "Whether the RDS instance should have storage encrypted. Defaults to false."
}

variable "rds_allocated_storage" {
  type        = number
  default     = 80
  description = "The allocated storage in gibibytes. Defaults to 80"
}

variable "rds_storage_type" {
  type        = string
  default     = "gp2"
  description = "The storage volume type (standard, gp2, gp3, io1, or io2). Defaults to gp2"
}

variable "rds_storage_throughput" {
  type        = number
  default     = null
  description = "The storage throughput (only valid when using rds_storage_type = gp3)"

}

variable "rds_iops" {
  type        = number
  default     = null
  description = "The storage provisioned IOPS  (only valid when using rds_storage_type = io1, io2, or gp3)"
}

variable "rds_multi_az" {
  type        = bool
  default     = false
  description = "Whether the RDS instance should have Multi-AZ enabled. Defaults to false."
}

variable "use_existing_temporal_cluster" {
  type        = bool
  default     = false
  description = "Whether to use an already existing Temporal Cluster. Defaults to false. Set to true and set temporal_cluster_config if you already have a Temporal cluster you want to use with Retool."
}

variable "launch_type" {
  type    = string
  default = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type must be either \"FARGATE\" or \"EC2\""
  }
}

# namescape: temporal namespace to use for Retool Workflows. We recommend this is only used by Retool.
# If use_existing_temporal_cluster == true this should be config for currently existing cluster. 
# If use_existing_temporal_cluster == false, you should use the defaults.
# hostname: hostname for Temporal Frontend service
# port: port for Temporal Frontend service
# tls_enabled: Whether to use tls when connecting to Temporal Frontend. For mTLS, configure tls_crt and tls_key.
# tls_crt: For mTLS only. Base64 encoded string of public tls certificate
# tls_key: For mTLS only. Base64 encoded string of private tls key
variable "temporal_cluster_config" {
  type = object({
    namespace   = string
    hostname    = string
    port        = string
    tls_enabled = bool
    tls_crt     = optional(string)
    tls_key     = optional(string)
  })

  default = {
    namespace   = "workflows"
    hostname    = "temporal"
    port        = "7233"
    tls_enabled = false
  }
}

variable "temporal_aurora_username" {
  type        = string
  default     = "retool"
  description = "Master username for the Temporal Aurora instance. Defaults to Retool."
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

variable "temporal_aurora_engine_version" {
  type        = string
  default     = "15.10"
  description = "Engine version for Temporal Aurora. Defaults to 15.10."
}

variable "temporal_aurora_serverless_min_capacity" {
  type        = number
  default     = 0.5
  description = "Minimum capacity for Temporal Aurora Serverless. Defaults to 0.5."
}

variable "temporal_aurora_serverless_max_capacity" {
  type        = number
  default     = 10
  description = "Maximum capacity for Temporal Aurora Serverless. Defaults to 10."
}

variable "temporal_aurora_backup_retention_period" {
  type        = number
  default     = 7
  description = "Number of days to retain backups for Temporal Aurora. Defaults to 7."
}

variable "temporal_aurora_preferred_backup_window" {
  type        = string
  default     = "03:00-04:00"
  description = "Preferred backup window for Temporal Aurora. Defaults to 03:00-04:00."
}

variable "temporal_aurora_instances" {
  type = any
  default = {
    one = {}
  }
}

variable "workflows_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable Workflows-specific containers, services, etc.. Defaults to false."
}

variable "code_executor_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable code_executor service to support Python execution. Defaults to false."
}

variable "telemetry_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable on-prem telemetry. Defaults to false."
}

variable "telemetry_send_to_retool" {
  type        = bool
  default     = true
  description = "Whether to send telemetry data to Retool. Defaults to true."
}

variable "telemetry_use_custom_config" {
  type        = bool
  default     = false
  description = "Whether to use custom Vector configuration. Defaults to false."
}

variable "telemetry_custom_config_path" {
  type        = string
  default     = "vector-custom.yaml"
  description = "Path to custom Vector configuration file for Retool telemetry. Defaults to vector-custom.yaml."
}

variable "enable_execute_command" {
  type        = bool
  default     = false
  description = "Whether to enable command execution on containers (for debugging). Defaults to false."
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Number of days to retain logs in CloudWatch. Defaults to 14."
}

variable "alb_idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle. Defaults to 60."
}

variable "alb_http_redirect" {
  type        = bool
  default     = false
  description = "Boolean for if http should redirect to https"
}

variable "cookie_insecure" {
  type        = bool
  default     = true
  description = "Whether to allow insecure cookies. Should be turned off when serving on HTTPS. Defaults to true."
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

variable "secret_length" {
  type        = number
  default     = 48
  description = "Length of secrets generated (e.g. ENCRYPTION_KEY, RDS_PASSWORD). Defaults to 48."
}

variable "autoscaling_memory_reservation_target" {
  type        = number
  default     = 70.0
  description = "Memory reservation target for the Autoscaling Group. Defaults to 70.0."
}

variable "additional_env_vars" {
  type        = list(map(string))
  default     = []
  description = "Additional environment variables (e.g. BASE_DOMAIN)"
}

variable "additional_temporal_env_vars" {
  type        = list(map(string))
  default     = []
  description = "Additional environment variables for Temporal containers (e.g. DYNAMIC_CONFIG_PATH)"
}

variable "container_ingress_rules" {
  type = map(
    object({
      description                  = string
      from_port                    = string
      to_port                      = string
      protocol                     = string
      cidr_block                   = optional(string)
      ipv6_cidr_block              = optional(string)
      referenced_security_group_id = optional(string)
    })
  )
  default = {
    first = {
      description = "Global HTTP inbound ipv4"
      from_port   = "80"
      to_port     = "3000"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    second = {
      description     = "Global HTTP inbound ipv6"
      from_port       = "80"
      to_port         = "3000"
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    },
    third = {
      description = "Global HTTPS inbound ipv4"
      from_port   = "443"
      to_port     = "3000"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    fourth = {
      description     = "Global HTTPS inbound ipv4"
      from_port       = "443"
      to_port         = "3000"
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    },
    fifth = {
      description = "SSH inbound ipv4"
      from_port   = "22"
      to_port     = "22"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    sixth = {
      description     = "SSH inbound ipv6"
      from_port       = "22"
      to_port         = "22"
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    }
  }
  description = "Ingress rules for EC2 instances in autoscaling group or ECS services in Fargate"
}


variable "container_egress_rules" {
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
  description = "Egress rules for EC2 instances in autoscaling group or ECS services in Fargate"
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
