# 1. Generate a secure, random 16-character password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" 
}

# 2. Build the PostgreSQL Database
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-${var.environment}-db"
  
  engine                 = "postgres"
  engine_version         = "15" # Or your preferred Postgres version
  
  # Dynamic Sizing: Larger for live, smaller for dev/staging
  instance_class         = var.environment == "live" ? "db.t3.medium" : "db.t3.micro"
  allocated_storage      = var.environment == "live" ? 50 : 20
  storage_type           = "gp3"

  # Inject the generated credentials
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result 

  # Network & Security
  db_subnet_group_name   = var.db_subnet_group
  vpc_security_group_ids = [var.db_security_group]
  
  publicly_accessible    = false 
  
  # High Availability: Multi-AZ only for live environments
  multi_az               = var.environment == "live" ? true : false
  skip_final_snapshot    = var.environment != "live"

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
  }
}

# 3. Create the empty Secret Vault
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.project_name}/${var.environment}/database/credentials"
  description = "Database credentials for Kaegro ${var.environment}"
  
  # Allow immediate deletion if destroying a dev environment
  recovery_window_in_days = var.environment == "live" ? 30 : 0
}

# 4. Save the credentials securely into the Vault as JSON
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  
  # This JSON structure makes it incredibly easy for kaegro/Docker to read later
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db_password.result
  })
}

# 6. Create the S3 Bucket for Static and Media files
module "s3" {
  source       = "../../modules/s3"
  
  environment  = var.environment
  project_name = var.project_name
}