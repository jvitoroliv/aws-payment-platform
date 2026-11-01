# output.tf
# Part of the output Terraform configuration module.

output "invoke_url" {
  value = aws_api_gateway_stage.api.invoke_url
}

output "execution_role_name" {
  value = aws_iam_role.function.name
}

output "function_name" {
  value = aws_lambda_function.function.function_name
}