locals {
  secrets_tags = merge(var.tags, {
    Component = "secrets"
  })
}

resource "random_password" "master" {
  length           = var.password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.name_prefix}-rds-credentials-"
  description             = "RDS master credentials (${var.name_prefix}) - managed by Terraform"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(local.secrets_tags, {
    Name = "${var.name_prefix}-rds-credentials"
  })
}
