# 1. Load Balancer Security Group (Public facing)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# 2. ECS Fargate Security Group (kaegro App)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allow inbound traffic ONLY from the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 8000 # kaegro's default port, or 80 if your container exposes 80
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Trust ONLY the ALB!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-sg"
    Environment = var.environment
  }
}

# 3. RDS Database Security Group (PostgreSQL/MySQL)
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow inbound traffic ONLY from ECS containers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ECS kaegro App"
    from_port       = 5432 # Change to 3306 if using MySQL instead of PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # Trust ONLY the ECS containers!
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}