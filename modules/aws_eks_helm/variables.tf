variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region. Defaults to `us-east-1`."
}

variable "deployment_name" {
  type        = string
  default     = "retool"
  description = "Deployment name that prefixes to resources created. Defaults to `retool`."
}
