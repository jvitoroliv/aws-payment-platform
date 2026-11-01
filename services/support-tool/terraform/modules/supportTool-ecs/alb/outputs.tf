# outputs.tf
# Part of the output value definitions module.

output "alb_dns_name" {
  value = aws_alb.alb_openjobs.dns_name
}

output "alb_zone_id" {
  value = aws_alb.alb_openjobs.zone_id
}

output "alb_target_group_arn" {
  value = aws_alb_target_group.alb_target_group.arn
}
