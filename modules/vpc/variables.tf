variable "environment" {
  description = "staging"
  type        = string
}

variable "project_name" {
  description = "Kaegro farm"
  type        = string
  default     = "kaegro"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (the total IP address pool)"
  type        = string
}

variable "public_subnets_cidr" {
  description = "List of public subnet CIDR blocks (for the Load Balancer)"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "List of private subnet CIDR blocks (for ECS and RDS)"
  type        = list(string)
}