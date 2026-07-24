output "security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "RDS Security Group ARN"
  value       = aws_security_group.rds.arn
}

output "enhanced_monitoring_role_arn" {
  description = "IAM role ARN for Enhanced Monitoring"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

output "iam_connect_role_arn" {
  description = "IAM role ARN for Database Authentication (if created)"
  value       = try(aws_iam_role.rds_iam_connect[0].arn, null)
}

output "iam_connect_role_name" {
  description = "IAM role name for Database Authentication (if created)"
  value       = try(aws_iam_role.rds_iam_connect[0].name, null)
}
