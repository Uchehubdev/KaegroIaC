variable "environment" { type = string }
variable "project_name" { type = string }

# 1. Create the empty Secret Vault
resource "aws_secretsmanager_secret" "kaegro_env" {
  name        = "${var.project_name}/${var.environment}/kaegro-secrets"
  description = "All .env variables for the Kaegro application"
  
  recovery_window_in_days = var.environment == "live" ? 30 : 0
}

output "secret_arn" {
  value = aws_secretsmanager_secret.kaegro_env.arn
}