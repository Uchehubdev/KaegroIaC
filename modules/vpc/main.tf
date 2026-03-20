# Fetch available Availability Zones in your current AWS region
data "aws_availability_zones" "available" {
  state = "available"
}

# Use the official production-tested AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  # Use the first two available zones in the region
  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets = var.private_subnets_cidr
  public_subnets  = var.public_subnets_cidr

  # 🚀 THE FIX: Dynamically calculate dedicated IPs for the Database so they never conflict
  database_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 20),
    cidrsubnet(var.vpc_cidr, 8, 21)
  ]

  # Create a NAT Gateway so your private ECS containers can securely download updates/images
  enable_nat_gateway = true
  
  # For Dev/Staging, use 1 NAT Gateway to save money. For Live, use 1 per zone for high availability.
  single_nat_gateway = var.environment != "live" 

  # Automatically group the database subnets together for your RDS database later
  create_database_subnet_group = true

  # Tag everything clearly for billing and management
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}