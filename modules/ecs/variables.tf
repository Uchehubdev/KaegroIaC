variable "environment" { type = string }
variable "project_name" { type = string }

# Network
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

# Security Groups
variable "ecs_security_group" { type = string }
variable "alb_security_group" { type = string }

# Secrets
variable "db_secret_arn" { type = string }
variable "kaegro_secret_arn" { type = string }

# Container
variable "docker_image_url" {
  description = "The URL of the Docker image to run. Defaults to a dummy image for the first build."
  type        = string
  default     = "nginx:latest" 
}