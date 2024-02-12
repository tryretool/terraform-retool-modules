variable "app_gw_subnet_cidr" {
  type        = list(string)
  description = "CIDR block for database subnet"
  default     = ["10.0.3.0/24"]
}

variable "app_gw_sku_name" {
  type        = string
  description = "Application gateway sku name"
  default     = "Standard_v2"
}

variable "app_gw_sku_tier" {
  type        = string
  description = "Application gateway sku tier"
  default     = "Standard_v2"
}
variable "default_node_count" {
  type        = string
  description = "Instance count for default node pool"
  default     = "1"
}

variable "default_node_size" {
  type        = string
  description = "Instance size for default node pool"
  default     = "Standard_D2_v4"
}

variable "db_instance_size" {
  type        = string
  description = "Instance size for external Azure Postgres server"
  default     = "GP_Standard_D4s_v3"
}

variable "k8s_dns_service_ip" {
  type        = string
  description = "IP for kube-dns within service range"
  default     = "10.1.1.1"
}

variable "k8s_max_node_count" {
  type        = number
  description = "Max number of nodes that can be autoscaled to"
  default     = 3
}

variable "k8s_node_size" {
  type        = string
  description = "VM size for retool node pool"
  default     = "Standard_D8_v4"
}

variable "k8s_service_cidr" {
  type        = string
  description = "CIDR block for k8s service"
  default     = "10.1.0.0/16"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version to launch"
  default     = "1.26.6"
}

variable "local_temporal" {
  type        = bool
  description = "Boolean to provision local temporal psql server"
  default     = false
}

variable "psql_db_name" {
  type        = string
  description = "Name for retool postgres database"
  default     = "retool"
}

variable "psql_subnet_cidr" {
  type        = list(string)
  description = "CIDR block for database subnet"
  default     = ["10.0.2.0/24"]
}

variable "psql_user" {
  type        = string
  description = "Admin username for postgres database"
  default     = "retool"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group to create resources in"
}

variable "ssh_key_path" {
  type        = string
  description = "Path to SSH key for connection to VM"
  default     = "~/.ssh/id_rsa.pub"
}

variable "subnet_name" {
  type        = string
  description = "Existing subnet to create k8s node pool in"
}

variable "temporal_db_name" {
  type        = string
  description = "Database name for temporal db"
  default     = "retool-temporal"
}

variable "temporal_user" {
  type        = string
  description = "Admin username for temporal postgres database"
  default     = "retool"
}

variable "use_app_gateway" {
  type        = bool
  description = "Boolean to provision application gateway"
  default     = false
}
variable "virtual_network_name" {
  type        = string
  description = "Existing vnet to create resources in"
}