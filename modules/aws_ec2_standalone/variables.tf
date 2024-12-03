variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region. Defaults to `us-east-1`."
}

variable "instance_type" {
  type        = string
  default     = "t3.xlarge"
  description = "EC2 instance type. Defaults to `t3.xlarge`."
}

variable "instance_name" {
  type        = string
  default     = "retool"
  description = "EC2 instance name. Defaults to `retool`."
}

variable "version_number" {
  type        = string
  default     = "2.106.2"
  description = "Retool version number. Defaults to `2.106.2`."
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "VPC to launch in."
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "VPC Subnet ID to launch in."
}

variable "ssh_key_name" {
  type        = string
  description = "EC2 SSH keypair"
}

variable "storage_size" {
  type        = number
  default     = 60
  description = "EBS storage size. Defaults to 60."
}

variable "storage_type" {
  type        = string
  default     = "gp2"
  description = "EBS storage type. Defaults to gp2."
}

variable "storage_encrypted" {
  type        = bool
  default     = true
  description = "Whether to encrypt EBS volume data."
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to attach to the EC2 instance"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = true
  description = "Whether to associate a public IP address with an instance in a VPC. Defaults to true."
}

variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "If true, the launched EC2 instance will have detailed monitoring enabled. Defaults to true."
}

variable "ingress_rules" {
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
    },
    {
      description      = "Global HTTPS inbound"
      from_port        = "443"
      to_port          = "443"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "SSH inbound"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "Application port inbound"
      from_port        = "3000"
      to_port          = "3000"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
  description = "Ingress rules for EC2 security group"
}


variable "egress_rules" {
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
  description = "Egress rules for EC2 security group"
}

