variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}