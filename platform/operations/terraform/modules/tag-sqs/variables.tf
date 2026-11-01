# variables.tf
# Part of the input variable declarations module.

# Type constraint catches misuse at plan time.
variable "environment" {
  type = string
}

variable "message_retention_seconds" {
  default = 1209600
  type    = number

  description = "Specifies the duration (in seconds) that Amazon SQS retains a message. After this period, the message is automatically deleted."

  validation {
    condition     = var.message_retention_seconds >= 604800
    error_message = "message_retention_seconds should be at least 7 days (604800 seconds)"
  }

}
variable "aws_region" {
  type = string
}
# Input validation ensures callers provide sane values.
variable "aws_account_number" {
  type = string
}
variable "app_file_storage" {
  type = string
}
variable "create_s3_bucket_notification" {
  default = true
  type    = bool
}
