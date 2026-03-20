output "alb_sg_id" {
  description = "The ID of the Load Balancer Security Group"
  value       = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  description = "The ID of the ECS Fargate Security Group"
  value       = aws_security_group.ecs_sg.id
}

output "rds_sg_id" {
  description = "The ID of the RDS Database Security Group"
  value       = aws_security_group.rds_sg.id
}