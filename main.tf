data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

data "aws_subnets" "existing_private" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}

module "networking" {
  source = "./modules/networking"
  count  = var.create_vpc ? 1 : 0

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

resource "aws_db_subnet_group" "existing" {
  count = var.create_vpc ? 0 : 1

  name        = "${local.name_prefix}-existing-db-subnet"
  description = "DB subnet group on existing subnets (${local.name_prefix})"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-existing-db-subnet"
  })
}

locals {
  vpc_id               = var.create_vpc ? module.networking[0].vpc_id : var.vpc_id
  vpc_cidr_block       = var.create_vpc ? module.networking[0].vpc_cidr_block : data.aws_vpc.existing[0].cidr_block
  private_subnet_ids   = var.create_vpc ? module.networking[0].private_subnet_ids : var.subnet_ids
  db_subnet_group_name = var.create_vpc ? module.networking[0].db_subnet_group_name : aws_db_subnet_group.existing[0].name

  effective_allowed_cidrs = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : (
    length(var.allowed_security_group_ids) > 0 ? [] : [local.vpc_cidr_block]
  )

  option_group_major = {
    mysql    = "8.0"
    mariadb  = "10.11"
    postgres = null
  }

  kms_key_arn = var.create_kms_key ? module.kms[0].key_arn : var.kms_key_arn
}

check "existing_network_required" {
  assert {
    condition     = var.create_vpc || (var.vpc_id != null && length(var.subnet_ids) >= 2)
    error_message = "When create_vpc = false, you must provide vpc_id and at least 2 subnet_ids."
  }
}

check "kms_key_required" {
  assert {
    condition     = var.create_kms_key || var.kms_key_arn != null
    error_message = "When create_kms_key = false, you must provide kms_key_arn."
  }
}

module "kms" {
  source = "./modules/kms"
  count  = var.create_kms_key ? 1 : 0

  name_prefix             = local.name_prefix
  deletion_window_in_days = var.kms_deletion_window_in_days
  tags                    = local.common_tags
}

module "security" {
  source = "./modules/security"

  name_prefix                = local.name_prefix
  vpc_id                     = local.vpc_id
  vpc_cidr_block             = local.vpc_cidr_block
  db_port                    = local.db_port
  engine                     = var.engine
  allowed_cidr_blocks        = local.effective_allowed_cidrs
  allowed_security_group_ids = var.allowed_security_group_ids
  tags                       = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"
  count  = var.manage_master_user_password ? 0 : 1

  name_prefix             = local.name_prefix
  kms_key_arn             = local.kms_key_arn
  recovery_window_in_days = var.secrets_recovery_window_in_days
  tags                    = local.common_tags

  depends_on = [module.kms]
}

module "rds" {
  source = "./modules/rds"

  identifier     = local.db_identifier
  engine         = var.engine
  engine_version = local.engine_version

  parameter_group_family            = local.parameter_family
  create_option_group               = local.create_option_group
  option_group_major_engine_version = lookup(local.option_group_major, var.engine, "8.0")

  instance_class              = var.instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = try(module.secrets[0].master_password, null)
  manage_master_user_password = var.manage_master_user_password
  port                        = local.db_port

  db_subnet_group_name   = local.db_subnet_group_name
  vpc_security_group_ids = [module.security.security_group_id]

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  kms_key_arn           = local.kms_key_arn

  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier
  deletion_protection       = var.deletion_protection

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = module.security.enhanced_monitoring_role_arn
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade

  create_read_replica         = var.create_read_replica
  read_replica_count          = var.read_replica_count
  read_replica_instance_class = var.read_replica_instance_class

  create_cloudwatch_alarms           = var.create_cloudwatch_alarms
  alarm_cpu_threshold                = var.alarm_cpu_threshold
  alarm_free_storage_threshold_bytes = var.alarm_free_storage_threshold_bytes
  alarm_connections_threshold        = var.alarm_connections_threshold
  alarm_sns_topic_arn                = var.alarm_sns_topic_arn

  tags = local.common_tags

  depends_on = [
    module.networking,
    module.kms,
    module.security
  ]
}

resource "aws_iam_policy" "rds_iam_connect" {
  count = var.iam_database_authentication_enabled ? 1 : 0

  name_prefix = "${local.name_prefix}-rds-connect-"
  description = "Allows connecting to RDS via IAM database authentication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSIAMConnect"
        Effect = "Allow"
        Action = ["rds-db:connect"]
        Resource = [
          "arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.rds.db_instance_resource_id}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials_with_host" {
  count = var.manage_master_user_password ? 0 : 1

  secret_id = module.secrets[0].secret_id

  secret_string = jsonencode({
    username             = var.db_username
    password             = module.secrets[0].master_password
    engine               = var.engine
    host                 = module.rds.db_instance_address
    port                 = module.rds.db_instance_port
    dbname               = var.db_name
    dbInstanceIdentifier = local.db_identifier
    resourceId           = module.rds.db_instance_resource_id
  })

  depends_on = [module.rds]
}
