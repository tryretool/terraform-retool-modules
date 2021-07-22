variable "eks_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "eks_name" {
  type        = string
  description = "EKS cluster name"
}

variable "eks_certificate_authority" {
  type        = string
  description = "EKS certificate authority"
}