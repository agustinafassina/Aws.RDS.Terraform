variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}

variable "engine" {
  description = "Engine: postgres, mysql, or mariadb"
  type        = string
}

variable "engine_version" {
  description = "Engine version"
  type        = string
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
}

variable "create_option_group" {
  description = "Create option group (MySQL/MariaDB)"
  type        = bool
  default     = false
}

variable "option_group_major_engine_version" {
  description = "Major version for the option group (e.g. 8.0, 10.11)"
  type        = string
  default     = "8.0"
}

variable "additional_parameters" {
  description = "Additional parameter group parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "instance_class" {
  description = "Instance class"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Master password (null if manage_master_user_password = true)"
  type        = string
  sensitive   = true
  default     = null
}

variable "manage_master_user_password" {
  description = "Use native RDS password management in Secrets Manager"
  type        = bool
  default     = false
}

variable "port" {
  description = "Database port"
  type        = number
}

variable "db_subnet_group_name" {
  description = "DB Subnet Group name"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of Security Group IDs"
  type        = list(string)
}

variable "allocated_storage" {
  description = "Initial storage (GiB)"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling (GiB); 0 disables"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "gp3 throughput (MiB/s)"
  type        = number
  default     = null
}

variable "kms_key_arn" {
  description = "CMK ARN for encryption"
  type        = string
}

variable "multi_az" {
  description = "Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window (UTC)"
  type        = string
}

variable "maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot ID"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = true
}

variable "iam_database_authentication_enabled" {
  description = "IAM Database Authentication"
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "RDS CA certificate identifier"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval (seconds)"
  type        = number
  default     = 60
}

variable "monitoring_role_arn" {
  description = "Enhanced Monitoring role ARN"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention (days)"
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Logs to export to CloudWatch (null = engine defaults)"
  type        = list(string)
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Auto minor version upgrade"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately (avoid in prod)"
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Create read replicas"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas"
  type        = number
  default     = 1
}

variable "read_replica_instance_class" {
  description = "Instance class for replicas"
  type        = string
  default     = null
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU threshold (%)"
  type        = number
  default     = 80
}

variable "alarm_free_storage_threshold_bytes" {
  description = "Free storage threshold (bytes)"
  type        = number
  default     = 10737418240
}

variable "alarm_connections_threshold" {
  description = "Connections threshold"
  type        = number
  default     = 100
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic for alarms"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
