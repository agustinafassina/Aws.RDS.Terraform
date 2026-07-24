variable "name_prefix" {
  description = "Prefix for security resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Security Group will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR (for restricted egress rules)"
  type        = string
}

variable "db_port" {
  description = "Database engine port"
  type        = number
}

variable "engine" {
  description = "Database engine (for rule descriptions)"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDRs authorized to connect to RDS"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Authorized application Security Groups"
  type        = list(string)
  default     = []
}

variable "create_iam_connect_role" {
  description = "Create sample IAM role for IAM Database Authentication"
  type        = bool
  default     = false
}

variable "iam_connect_principal_arns" {
  description = "Principal ARNs that can assume the IAM connect role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
