variable "deployment_name" {
  type        = string
  description = "Name prefix for created resources. Defaults to `retool`."
  default     = "retool"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region. Defaults to `us-east-1`."
}
