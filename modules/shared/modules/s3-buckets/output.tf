# output.tf
# Part of the output Terraform configuration module.

#Outputs

output "aws_s3_bucket_name" {
  value = aws_s3_bucket.lambda_content.id
}

output "aws_s3_bucket_arn" {
  value = aws_s3_bucket.lambda_content.arn
}

output "aws_s3_bucket_access_log_name" {
  value = aws_s3_bucket.access_logs.id
}

output "aws_s3_bucket_access_log_arn" {
  value = aws_s3_bucket.access_logs.arn
}