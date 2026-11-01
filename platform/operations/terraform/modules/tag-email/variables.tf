# variables.tf
# Part of the input variable declarations module.

# Input validation ensures callers provide sane values.
variable "aws_region" {
  type = string
}

variable "email_bounce_queue_arn" {
  type = string
}

variable "email_domain" {
  type = string
}

variable "environment" {
  type = string
}

variable "incoming_mail_bucket_id" {
  type = string
}
