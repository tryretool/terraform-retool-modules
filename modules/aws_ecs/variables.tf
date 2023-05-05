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
  description = "Select at two subnets in your selected VPC."
}

variable "ssh_key_name" {
  type        = string
  description = "SSH key name for accessing EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "ECS cluster instance type. Defaults to `t2.large`"
  default     = "t2.large"
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

variable "retool_license_key" {
  type        = string
  description = "Retool license key"
  default     = "EXPIRED-LICENSE-KEY-TRIAL"
}

variable "ecs_retool_image" {
  type        = string
  description = "Container image for desired Retool version. Defaults to `2.106.2`"
  default     = "tryretool/backend:2.116.3"
}

variable "ecs_task_resource_map" {
  type        = map(object({
    cpu = number
    memory = number
  }))
  default     = {
    main = {
      cpu = 2048
      memory = 4096
    },
    jobs_runner = {
      cpu = 1024
      memory = 2048
    },
    workflows_backend = {
      cpu = 2048
      memory = 4096
    }
    workflows_worker = {
      cpu = 2048
      memory = 4096
    }
  }
  description = "Amount of CPU and Memory provisioned for each task."
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

variable "rds_publicly_accessible" {
  type        = bool
  default     = true
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

variable "use_exising_temporal_cluster" {
  type        = bool
  default     = false
  description = "Whether to use an already existing Temporal Cluster. Defaults to false. Set to true and set temporal_cluster_config if you already have a Temporal cluster you want to use with Retool."
}

variable "launch_type" {
  type        = string
  default     = "FARGATE"

  validation {
    condition = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type must be either \"FARGATE\" or \"EC2\""
  }
}

# namescape: temporal namespace to use for Retool Workflows. We recommend this is only used by Retool.
# If use_existing_temporal_cluster == true this should be config for currently existing cluster. 
# If use_existing_temporal_cluster == false, you should use the defaults.
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

variable "workflows_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable Workflows-specific containers, services, etc.. Defaults to false."
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
      description      = "Global HTTP inbound ipv4"
      from_port        = "80"
      to_port          = "3000"
      protocol         = "tcp"
      cidr_block       = "0.0.0.0/0"
    },
    second = {
      description      = "Global HTTP inbound ipv6"
      from_port        = "80"
      to_port          = "3000"
      protocol         = "tcp"
      ipv6_cidr_block  = "::/0"
    },
    third = {
      description      = "Global HTTPS inbound ipv4"
      from_port        = "443"
      to_port          = "3000"
      protocol         = "tcp"
      cidr_block       = "0.0.0.0/0"
    },
    fourth = {
      description      = "Global HTTPS inbound ipv4"
      from_port        = "443"
      to_port          = "3000"
      protocol         = "tcp"
      ipv6_cidr_block  = "::/0"
    },
    fifth = {
      description      = "SSH inbound ipv4"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      cidr_block       = "0.0.0.0/0"
    },
    sixth = {
      description      = "SSH inbound ipv6"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      ipv6_cidr_block  = "::/0"
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
