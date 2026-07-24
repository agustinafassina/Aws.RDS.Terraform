variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name (used in resource names and tags)"
  type        = string
  default     = "rds-secure"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,30}$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, numbers, and hyphens (max 31 characters)."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be: dev, staging, or prod."
  }
}

variable "create_vpc" {
  description = "If true, create a new VPC with private subnets. If false, use existing vpc_id and subnet_ids"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR (only when create_vpc = true)"
  type        = string
  default     = "10.50.0.0/16"
}

variable "vpc_id" {
  description = "Existing VPC ID (required when create_vpc = false)"
  type        = string
  default     = null
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for RDS (minimum 2 AZs). Only when create_vpc = true"
  type        = list(string)
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (NAT Gateway). Only when create_vpc = true"
  type        = list(string)
  default     = ["10.50.101.0/24", "10.50.102.0/24"]
}

variable "subnet_ids" {
  description = "Existing private subnet IDs (minimum 2 AZs). Required when create_vpc = false"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to connect to the database port (least privilege)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Application security groups allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so Enhanced Monitoring / logs can reach AWS APIs (recommended)"
  type        = bool
  default     = true
}

variable "engine" {
  description = "Database engine: postgres, mysql, or mariadb"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "engine must be: postgres, mysql, or mariadb."
  }
}

variable "engine_version" {
  description = "Engine version. If null, the recommended version from locals is used"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family. If null, it is inferred from the engine"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_username" {
  description = "Master database username (password is generated and stored in Secrets Manager)"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_port" {
  description = "Database port. If null, the engine default port is used"
  type        = number
  default     = null
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t4g.medium, db.r6g.large)"
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Initial storage size in GiB"
  type        = number
  default     = 100

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling size in GiB (0 disables autoscaling)"
  type        = number
  default     = 500
}

variable "storage_type" {
  description = "Storage type: gp3 (recommended), gp2, io1, or io2"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be: gp2, gp3, io1, or io2."
  }
}

variable "iops" {
  description = "Provisioned IOPS (required for io1/io2; optional for gp3 > 3000)"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "gp3 throughput in MiB/s (optional)"
  type        = number
  default     = null
}

variable "multi_az" {
  description = "Deploy Multi-AZ for high availability"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Automated backup retention in days (minimum 7 recommended by AWS)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 7 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 7 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window in UTC (hh24:mi-hh24:mi)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window in UTC during low traffic (ddd:hh24:mi-ddd:hh24:mi)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Automatically apply minor engine upgrades"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect against accidental deletion (recommended true in prod)"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "If true, skip the final snapshot on destroy (NOT recommended in prod)"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier. If null, one is generated automatically"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy instance tags to snapshots"
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create a customer-managed KMS key. If false, use kms_key_arn or an AWS-managed key"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing CMK ARN (used when create_kms_key = false)"
  type        = string
  default     = null
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period in days before CMK deletion (7-30)"
  type        = number
  default     = 30
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Whether the instance is publicly accessible (must be false)"
  type        = bool
  default     = false

  validation {
    condition     = var.publicly_accessible == false
    error_message = "publicly_accessible must be false for security (RDS in private subnets)."
  }
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be: 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days (7 or 731)"
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch. If null, engine defaults are used"
  type        = list(string)
  default     = null
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for CPU, storage, and connections"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization alarm threshold (%)"
  type        = number
  default     = 80
}

variable "alarm_free_storage_threshold_bytes" {
  description = "Free storage space alarm threshold (bytes)"
  type        = number
  default     = 10737418240
}

variable "alarm_connections_threshold" {
  description = "Active connections alarm threshold"
  type        = number
  default     = 100
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (optional)"
  type        = string
  default     = null
}

variable "create_read_replica" {
  description = "Create a read replica of the primary instance"
  type        = bool
  default     = false
}

variable "read_replica_instance_class" {
  description = "Read replica instance class. If null, the primary class is used"
  type        = string
  default     = null
}

variable "read_replica_count" {
  description = "Number of read replicas to create (only when create_read_replica = true)"
  type        = number
  default     = 1

  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 5
    error_message = "read_replica_count must be between 0 and 5."
  }
}

variable "secrets_recovery_window_in_days" {
  description = "Secret recovery window in days after deletion (0 = immediate delete)"
  type        = number
  default     = 30
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in Secrets Manager (AWS-managed)"
  type        = bool
  default     = false
}
