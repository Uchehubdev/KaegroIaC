variable "environment" {
  description = "The environment (dev, staging, live)"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
  default     = "kaegro"
}

variable "db_subnet_group" {
  description = "The database subnet group from the VPC"
  type        = string
}

variable "db_security_group" {
  description = "The security group ID for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the initial database"
  type        = string
  default     = "kaegrodb"
}

variable "db_username" {
  description = "The master username"
  type        = string
  default     = "kaegroadmin"
}