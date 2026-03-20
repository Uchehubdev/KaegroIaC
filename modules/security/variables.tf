variable "environment" {
  description = "staging)"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "kaegro"
}

variable "vpc_id" {
  description = "The ID of the VPC where these security groups will be created"
  type        = string
}