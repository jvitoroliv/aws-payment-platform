# output.tf
# Part of the output Terraform configuration module.

#Outputs

output "splunklogger_lambda_name" {
  value = aws_lambda_function.splunklogger.function_name
}

output "splunklogger_lambda_arn" {
  value = aws_lambda_function.splunklogger.arn
}
