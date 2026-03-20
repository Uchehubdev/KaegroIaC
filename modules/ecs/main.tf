# ==========================================
# 1. LOAD BALANCER & ROUTING
# ==========================================
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 8000 # The port your Kaegro Docker container exposes
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/" # Change this to a dedicated health check URL if you have one
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  # For production, you will change this to redirect to HTTPS
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ==========================================
# 2. IAM PERMISSIONS (To read secrets)
# ==========================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach standard ECS permissions
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grant permission to read our specific Secret Vaults
resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.project_name}-${var.environment}-secrets-policy"
  description = "Allow ECS to read Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        var.db_secret_arn,
        var.kaegro_secret_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

# ==========================================
# 3. ECS CLUSTER & LOGS
# ==========================================
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 14
}

# ==========================================
# 4. TASK DEFINITION & SERVICE
# ==========================================
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "kaegro-app"
    image     = var.docker_image_url
    essential = true
    
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
    }]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    # This is where AWS combines both secret vaults into environment variables!
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "${var.db_secret_arn}:password::"
      },
      {
        name      = "DB_HOST"
        valueFrom = "${var.db_secret_arn}:host::"
      },
      {
        name      = "DB_USER"
        valueFrom = "${var.db_secret_arn}:username::"
      },
      {
        name      = "DB_NAME"
        valueFrom = "${var.db_secret_arn}:dbname::"
      },
      {
        name      = "DB_PORT"
        valueFrom = "${var.db_secret_arn}:port::"
      },
      {
        name      = "kaegro_SECRET_KEY"
        valueFrom = "${var.kaegro_secret_arn}:kaegro_SECRET_KEY::"
      }
      # You can add more mapping here as your .env grows
    ]
  }])
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1 # Number of containers to run
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    security_groups  = [var.ecs_security_group]
    subnets          = var.private_subnets
    assign_public_ip = false # Hidden safely in the private subnet
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "kaegro-app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}