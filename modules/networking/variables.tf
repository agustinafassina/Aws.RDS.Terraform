variable "name_prefix" {
  description = "Prefix for networking resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets (minimum 2)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets (2 AZs) are required for Multi-AZ / DB Subnet Group."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (NAT Gateway)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway and Internet Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to networking resources"
  type        = map(string)
  default     = {}
}
