variable "region" {
  type        = string
  description = "Region of deployment"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster"
}

variable "node_pool_name" {
  type        = string
  description = "Name of the Node pool"
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Node count for the node pool. Defaults to 1."
}

variable "node_machine_type" {
  type        = string
  default     = "e2-medium"
  description = "Machine type of nodes. Defaults to `e2-medium`"
}

variable "database_name" {
  type        = string
  description = "Name of the postgres database"
}

variable "database_tier" {
  type        = string
  default     = "db-f1-micro"
  description = "Tier of the database instance"
}

variable "helm_values_path" {
  type        = string
  description = "Helm values path"
}
