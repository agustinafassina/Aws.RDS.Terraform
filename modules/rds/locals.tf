locals {
  rds_tags = merge(var.tags, {
    Component = "rds"
  })

  default_cloudwatch_logs = {
    postgres = ["postgresql", "upgrade"]
    mysql    = ["error", "general", "slowquery"]
    mariadb  = ["error", "general", "slowquery", "audit"]
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
