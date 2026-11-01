# outputs.tf
# Manages output value definitions resources.

output "incoming_mail_storage" {
  value = aws_s3_bucket.aoc_incoming_mail.id
}

output "app_script_storage" {
  value = aws_s3_bucket.app_script_storage.id
}
