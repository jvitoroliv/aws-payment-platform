# output.tf
# Manages output Terraform configuration resources.

output "function_invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "execution_role_name" {
  value = aws_iam_role.function.name
}

output "function_name" {
  value = aws_lambda_function.function.function_name
}