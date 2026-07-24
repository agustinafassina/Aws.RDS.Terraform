locals {
  name_prefix = lower(replace(var.project_name, "_", "-"))

  common_tags = {
    project_name = var.project_name
    environment  = var.environment
  }

  engine_ports = {
    postgres = 5432
    mysql    = 3306
    mariadb  = 3306
  }

  recommended_engine_versions = {
    postgres = "16.4"
    mysql    = "8.0.39"
    mariadb  = "10.11.9"
  }

  parameter_group_families = {
    postgres = "postgres16"
    mysql    = "mysql8.0"
    mariadb  = "mariadb10.11"
  }

  option_group_engines = {
    mysql   = "mysql"
    mariadb = "mariadb"
  }

  db_port             = coalesce(var.db_port, local.engine_ports[var.engine])
  engine_version      = coalesce(var.engine_version, local.recommended_engine_versions[var.engine])
  parameter_family    = coalesce(var.parameter_group_family, local.parameter_group_families[var.engine])
  create_option_group = contains(["mysql", "mariadb"], var.engine)
  db_identifier       = "${local.name_prefix}-${var.environment}-rds"
  create_vpc          = var.create_vpc
}
