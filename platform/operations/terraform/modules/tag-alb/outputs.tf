# outputs.tf
# Manages output value definitions resources.

output "alb_listener_arns" {
  value = aws_lb_listener.lb_listener[*].arn
}

output "alb_tg_arns" {
  value = aws_lb_target_group.tg[*].arn
}

output "alb_name" {
  value = aws_lb.lb.name
}

output "alb_zone_id" {
  value = aws_lb.lb.zone_id
}

output "alb_dns_name" {
  value = aws_lb.lb.dns_name
}

output "alb_security_groups" {
  value = aws_lb.lb.security_groups
}

