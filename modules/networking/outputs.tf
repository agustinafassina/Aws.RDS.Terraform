output "vpc_id" {
  description = "Created VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "db_subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "DB Subnet Group ARN"
  value       = aws_db_subnet_group.this.arn
}

output "availability_zones" {
  description = "AZs used by the subnets"
  value       = local.azs
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if created)"
  value       = try(aws_nat_gateway.this[0].id, null)
}
