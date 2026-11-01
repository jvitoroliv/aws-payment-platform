# outputs.tf
# Manages output value definitions resources.

output "task_name" {
  value = aws_ecs_task_definition.tagcore.arn
}