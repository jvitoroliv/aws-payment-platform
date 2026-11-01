# outputs.tf
# Part of the output value definitions module.

output "cluster_id" {
  value = aws_ecs_cluster.tagcore.id
}

output "cluster_name" {
  value = aws_ecs_cluster.tagcore.name
}

output "dd_log_group_name" {
  value = aws_cloudwatch_log_group.datadog.name
}