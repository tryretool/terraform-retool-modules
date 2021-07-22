output "eks_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster endpoint"
}

output "eks_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "eks_certificate_authority" {
  value       = aws_eks_cluster.this.certificate_authority.0.data
  description = "EKS certificate authority"
}
