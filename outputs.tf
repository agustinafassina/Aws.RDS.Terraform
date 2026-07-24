output "vpc_id" {
  description = "VPC ID in use"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = local.private_subnet_ids
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = local.db_subnet_group_name
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = module.security.security_group_id
}

output "kms_key_arn" {
  description = "KMS CMK ARN used for encryption"
  value       = local.kms_key_arn
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = module.rds.db_instance_id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "db_instance_endpoint" {
  description = "Full endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "Database port"
  value       = module.rds.db_instance_port
}

output "db_instance_name" {
  description = "Database name"
  value       = module.rds.db_instance_name
}

output "db_instance_resource_id" {
  description = "Resource ID (for IAM rds-db:connect policies)"
  value       = module.rds.db_instance_resource_id
}

output "db_connection_string_hint" {
  description = "Connection string hint (no password; retrieve it from Secrets Manager)"
  sensitive   = true
  value = (
    var.engine == "postgres"
    ? "postgresql://${var.db_username}@${module.rds.db_instance_address}:${module.rds.db_instance_port}/${var.db_name}?sslmode=require"
    : "mysql://${var.db_username}@${module.rds.db_instance_address}:${module.rds.db_instance_port}/${var.db_name}?ssl-mode=REQUIRED"
  )
}

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN with credentials (when not using manage_master_user_password)"
  value       = try(module.secrets[0].secret_arn, module.rds.master_user_secret_arn)
  sensitive   = true
}

output "rds_iam_connect_policy_arn" {
  description = "IAM policy ARN for database authentication"
  value       = try(aws_iam_policy.rds_iam_connect[0].arn, null)
}

output "read_replica_endpoints" {
  description = "Read replica endpoints"
  value       = module.rds.read_replica_endpoints
}

output "enhanced_monitoring_role_arn" {
  description = "Enhanced Monitoring IAM role ARN"
  value       = module.security.enhanced_monitoring_role_arn
}

output "cloudwatch_log_exports" {
  description = "Log types exported to CloudWatch"
  value       = module.rds.cloudwatch_log_exports
}

output "aws_region" {
  description = "Deployment region"
  value       = data.aws_region.current.region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
