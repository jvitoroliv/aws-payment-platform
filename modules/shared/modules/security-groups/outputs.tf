# outputs.tf
# Manages output value definitions resources.

output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value       = { for sg_name, sg in aws_security_group.this : sg_name => sg.id }
}

output "security_groups" {
  description = "Map of all security group resources"
  value       = aws_security_group.this
}
