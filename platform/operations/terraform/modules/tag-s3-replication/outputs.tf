# outputs.tf
# Manages output value definitions resources.

output "primary_app_file_storage" {
  value = aws_s3_bucket.primary_app_file_storage.id
}

output "secondary_app_file_storage" {
  value = aws_s3_bucket.secondary_app_file_storage.id
}
