resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  license_model        = var.engine == "postgres" ? "postgresql-license" : null
  parameter_group_name = aws_db_parameter_group.this.name
  option_group_name    = var.create_option_group ? aws_db_option_group.this[0].name : null

  db_name  = var.db_name
  username = var.username
  password = var.manage_master_user_password ? null : var.password
  port     = var.port

  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.kms_key_arn : null

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false
  network_type           = "IPV4"

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn
  iops                  = local.apply_iops ? var.iops : null
  storage_throughput    = var.storage_type == "gp3" ? var.storage_throughput : null

  multi_az = var.multi_az

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_id
  deletion_protection       = var.deletion_protection
  delete_automated_backups  = false

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  ca_cert_identifier                  = var.ca_cert_identifier

  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  enabled_cloudwatch_logs_exports       = local.cloudwatch_logs_exports

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  tags = merge(local.rds_tags, {
    Name = var.identifier
  })

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }

  depends_on = [
    aws_db_parameter_group.this
  ]
}

resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? var.read_replica_count : 0

  identifier          = "${var.identifier}-replica-${count.index + 1}"
  instance_class      = coalesce(var.read_replica_instance_class, var.instance_class)
  replicate_source_db = aws_db_instance.this.identifier

  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false

  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn
  storage_type          = var.storage_type
  iops                  = local.apply_iops ? var.iops : null
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null

  multi_az = false

  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  enabled_cloudwatch_logs_exports       = local.cloudwatch_logs_exports

  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = true
  apply_immediately                   = var.apply_immediately
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  ca_cert_identifier                  = var.ca_cert_identifier
  parameter_group_name                = aws_db_parameter_group.this.name

  tags = merge(local.rds_tags, {
    Name = "${var.identifier}-replica-${count.index + 1}"
    Role = "read-replica"
  })
}
