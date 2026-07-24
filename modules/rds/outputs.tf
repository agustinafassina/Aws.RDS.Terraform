output "db_instance_id" {
  description = "RDS instance ID / identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "Instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Instance hostname"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "Instance port"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_resource_id" {
  description = "Resource ID (useful for IAM Database Authentication)"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "Instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_availability_zone" {
  description = "Primary AZ"
  value       = aws_db_instance.this.availability_zone
}

output "db_instance_multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = aws_db_instance.this.multi_az
}

output "db_parameter_group_id" {
  description = "Parameter group ID"
  value       = aws_db_parameter_group.this.id
}

output "db_option_group_id" {
  description = "Option group ID (if applicable)"
  value       = try(aws_db_option_group.this[0].id, null)
}

output "read_replica_ids" {
  description = "Read replica identifiers"
  value       = aws_db_instance.replica[*].id
}

output "read_replica_endpoints" {
  description = "Read replica endpoints"
  value       = aws_db_instance.replica[*].endpoint
}

output "read_replica_arns" {
  description = "Read replica ARNs"
  value       = aws_db_instance.replica[*].arn
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed secret (if manage_master_user_password = true)"
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "cloudwatch_log_exports" {
  description = "Logs exported to CloudWatch"
  value       = local.cloudwatch_logs_exports
}
