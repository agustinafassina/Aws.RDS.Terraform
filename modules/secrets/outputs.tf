output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_id" {
  description = "Secret ID"
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "secret_name" {
  description = "Secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "master_password" {
  description = "Generated master password (sensitive — prefer reading from Secrets Manager)"
  value       = random_password.master.result
  sensitive   = true
}
