output "db_endpoint" {
  description = "The connection endpoint for the database"
  # AWS returns this as 'url:port', which is exactly what kaegro needs
  value       = aws_db_instance.postgres.endpoint 
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.postgres.db_name
}

# Add this missing block so the ECS module can find the password!
output "secret_arn" {
  description = "The ARN of the Secrets Manager vault containing the DB credentials"
  value       = aws_secretsmanager_secret.db_secret.arn
}