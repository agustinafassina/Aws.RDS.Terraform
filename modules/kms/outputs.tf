output "key_id" {
  description = "CMK ID"
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "CMK ARN"
  value       = aws_kms_key.this.arn
}

output "alias_name" {
  description = "CMK alias"
  value       = aws_kms_alias.this.name
}

output "alias_arn" {
  description = "CMK alias ARN"
  value       = aws_kms_alias.this.arn
}
