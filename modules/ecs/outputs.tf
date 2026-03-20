output "alb_dns_name" {
  description = "The public web address of the Load Balancer"
  value       = aws_lb.main.dns_name
}