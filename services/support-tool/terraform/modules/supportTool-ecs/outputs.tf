# outputs.tf
# Manages output value definitions resources.

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "service_name" {
  value = aws_ecs_service.api.name
}

output "security_group_id" {
  value = aws_security_group.ecs_service.id
}
