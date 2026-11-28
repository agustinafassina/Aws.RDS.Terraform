locals {
  rds_tags = merge(var.tags, {
    Component = "rds"
  })

  general_log_export = var.enable_general_log ? ["general"] : []

  default_cloudwatch_logs = {
    postgres = ["postgresql", "upgrade"]
    mysql    = concat(["error", "slowquery"], local.general_log_export)
    mariadb  = concat(["error", "slowquery", "audit"], local.general_log_export)
  }

  cloudwatch_logs_exports = coalesce(
    var.enabled_cloudwatch_logs_exports,
    local.default_cloudwatch_logs[var.engine]
  )

  final_snapshot_id = var.skip_final_snapshot ? null : coalesce(
    var.final_snapshot_identifier,
    "${var.identifier}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )

  apply_iops = contains(["io1", "io2"], var.storage_type) || (var.storage_type == "gp3" && var.iops != null)
}
