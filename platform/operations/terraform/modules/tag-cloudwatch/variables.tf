# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  type = string
}

# Input validation ensures callers provide sane values.
variable "aws_region" {
  type = string
}

variable "monthly_cron" {
  type = string
}

variable "quarterly_cron" {
  type = string
}

variable "scheduled_event_queue_arn" {
  type = string
}

variable "is_enabled" {
  type = bool
}