locals {
  security_tags = merge(var.tags, {
    Component = "security"
  })
}

resource "aws_security_group" "rds" {
  name_prefix            = "${var.name_prefix}-rds-"
  description            = "Restrictive Security Group for RDS (${var.name_prefix}) - least privilege"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.security_tags, {
    Name = "${var.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  type              = "ingress"
  description       = "Access to ${var.engine} from authorized CIDR"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "ingress_sg" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  description              = "Access to ${var.engine} from application SG"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
}

resource "aws_security_group_rule" "egress_vpc" {
  type              = "egress"
  description       = "Response traffic within the VPC"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.rds.id
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "${var.name_prefix}-rds-mon-"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  description        = "IAM role for RDS Enhanced Monitoring (${var.name_prefix})"

  tags = merge(local.security_tags, {
    Name = "${var.name_prefix}-rds-enhanced-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_connect_assume" {
  count = var.create_iam_connect_role ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.iam_connect_principal_arns
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_iam_connect" {
  count = var.create_iam_connect_role ? 1 : 0

  name_prefix        = "${var.name_prefix}-rds-connect-"
  assume_role_policy = data.aws_iam_policy_document.rds_connect_assume[0].json
  description        = "Role for IAM Database Authentication (${var.name_prefix})"

  tags = merge(local.security_tags, {
    Name = "${var.name_prefix}-rds-iam-connect"
  })
}
