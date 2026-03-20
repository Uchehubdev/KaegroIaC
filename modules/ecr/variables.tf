variable "environment" {
  description = "The environment (dev, staging, live)"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
  default     = "kaegro"
}