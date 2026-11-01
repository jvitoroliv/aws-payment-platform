# output.tf
# Manages output Terraform configuration resources.

#Outputs

output "splunklogger_s3_lambda_name" {
  value = aws_lambda_function.splunklogger_s3.function_name
}

output "splunklogger_s3_lambda_arn" {
  value = aws_lambda_function.splunklogger_s3.arn
}
