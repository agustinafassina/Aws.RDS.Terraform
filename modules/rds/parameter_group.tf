resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Secure parameter group for ${var.engine} (${var.identifier})"

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "log_connections"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "log_statement"
      value        = "ddl"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "log_min_duration_statement"
      value        = "1000"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements"
      apply_method = "pending-reboot"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name         = "require_secure_transport"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name         = "long_query_time"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name         = "general_log"
      value        = "1"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name         = "log_output"
      value        = "FILE"
      apply_method = "immediate"
    }
  }

  dynamic "parameter" {
    for_each = var.additional_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(local.rds_tags, {
    Name = "${var.identifier}-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "this" {
  count = var.create_option_group ? 1 : 0

  name_prefix              = "${var.identifier}-opt-"
  engine_name              = var.engine == "mariadb" ? "mariadb" : "mysql"
  major_engine_version     = var.option_group_major_engine_version
  option_group_description = "Option group for ${var.engine} (${var.identifier})"

  dynamic "option" {
    for_each = var.engine == "mariadb" ? [1] : []
    content {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings {
        name  = "SERVER_AUDIT_EVENTS"
        value = "CONNECT,QUERY,TABLE"
      }

      option_settings {
        name  = "SERVER_AUDIT_EXCL_USERS"
        value = "rdsadmin"
      }
    }
  }

  tags = merge(local.rds_tags, {
    Name = "${var.identifier}-option-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}
