output "ecs_alb_url" {
  value       = aws_lb.this.dns_name
  description = "Retool ALB DNS url (where Retool is running)"
}

output "ecs_alb_arn" {
  value       = aws_lb.this.arn
  description = "Retool ALB arn"
}

output "ecs_alb_security_group_arn" {
  value       = aws_security_group.alb.arn
  description = "Security Group arn for Retool ALB"
}

output "ecs_alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security Group ID for Retool ALB"
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

output "ecs_ec2_security_group_arn" {
  value       = aws_security_group.ec2.arn
  description = "Security Group arn for Retool ec2"
}

output "ecs_ec2_security_group_id" {
  value       = aws_security_group.ec2.id
  description = "Security Group ID for Retool ec2"
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

output "rds_security_group_arn" {
  value       = aws_security_group.rds.arn
  description = "Security Group arn for RDS instance"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Security Group ID for RDS instance"
}
