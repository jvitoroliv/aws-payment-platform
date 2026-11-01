# outputs.tf
# Part of the output value definitions module.

output "support_box_name" {
  value = aws_instance.support.id
}