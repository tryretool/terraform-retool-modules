output "ecs_alb_url" {
  value       = aws_lb.this.dns_name
  description = "Retool ALB DNS url (where Retool is running)"
}

output "ecs_alb_arn" {
  value       = aws_lb.this.arn
  description = "Retool ALB arn"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "Name of AWS ECS Cluster"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "ARN of AWS ECS Cluster"
}

output "ecs_cluster_id" {
  value       = aws_ecs_cluster.this.id
  description = "ID of AWS ECS Cluster"
}

output "rds_instance_id" {
  value       = aws_db_instance.this.id
  description = "ID of AWS RDS instance"
}

output "rds_instance_address" {
  value       = aws_db_instance.this.address
  description = "Hostname of the RDS instance"
}

output "rds_instance_arn" {
  value       = aws_db_instance.this.arn
  description = "ARN of RDS instance"
}

output "rds_instance_name" {
  value       = aws_db_instance.this.db_name
  description = "Name of RDS instance"
}
