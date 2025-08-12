output "ec2_arn" {
  value       = aws_instance.this.arn
  description = "ARN of EC2 Instance"
}

output "ec2_id" {
  value       = aws_instance.this.id
  description = "ID of EC2 Instance"
}

output "ec2_public_dns" {
  value       = aws_instance.this.public_dns
  description = "Public DNS of EC2 Instance"
}

output "ec2_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP of EC2 Instance"
}

output "ec2_security_group_arn" {
  value       = aws_security_group.this.arn
  description = "Security Group arn for EC2 instance"
}

output "ec2_security_group_id" {
  value       = aws_security_group.this.id
  description = "Security Group ID for EC2 instance"
}
