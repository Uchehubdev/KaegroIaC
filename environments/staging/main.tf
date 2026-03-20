# 1. Configure Terraform and the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "default" 
}

# 2. Call our custom VPC Module
module "vpc" {
  source               = "../../modules/vpc" 
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}

# 3. Call our custom Security Groups Module
module "security" {
  source       = "../../modules/security"
  
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id 
}

# 4. Call our custom Database Module
module "database" {
  source            = "../../modules/database"
  
  environment       = var.environment
  project_name      = var.project_name
  db_subnet_group   = module.vpc.db_subnet_group_name
  db_security_group = module.security.rds_sg_id
}

# 5. Create the kaegro Secrets Vault
module "kaegro_secrets" {
  source       = "../../modules/secrets"
  
  environment  = var.environment
  project_name = var.project_name
}

# 6. Create the Elastic Container Registry (ECR)
module "ecr" {
  source       = "../../modules/ecr"
  
  environment  = var.environment
  project_name = var.project_name
}

# 7. Create the ECS Fargate Service
module "ecs" {
  source              = "../../modules/ecs"
  environment         = var.environment
  project_name        = var.project_name
  
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  private_subnets     = module.vpc.private_subnet_ids
  ecs_security_group  = module.security.ecs_sg_id
  alb_security_group  = module.security.alb_sg_id
  
  db_secret_arn       = module.database.secret_arn
  kaegro_secret_arn   = module.kaegro_secrets.secret_arn
  
  docker_image_url = "${module.ecr.repository_url}"
}

# Output the URL so we can click it!
output "kaegro_dev_url" {
  value = module.ecs.alb_dns_name
}