# variables.tf
# Part of the input variable declarations module.

variable "environment" {
  type = string
}

variable "health_check_enabled" {
  default = true
  type    = bool
}

# Defaults are production-safe; override per environment.
variable "health_check_healthy_threshold" {
  default = 2
  type    = number
}

variable "health_check_interval" {
  default = 10
  type    = number
}

variable "health_check_matcher" {
  default = 200
  type    = number
}

variable "health_check_path" {
  default = "/"
  type    = string
}

variable "health_check_port" {
  default = "traffic-port"
  type    = string
}

variable "health_check_timeout" {
  default = 5
  type    = number
}

variable "health_check_unhealthy_threshold" {
  default = 2
  type    = number
}

variable "idle_timeout" {
  default = 60
  type    = number
}

# Input validation ensures callers provide sane values.
variable "internal" {
  default = false
  type    = bool
}

variable "lb_name" {
  type = string
}

# Documented in the module README with accepted ranges.
variable "listener_targets" {
  description = "List of LB targets. A new listener is created for each target. First target should always be 443."
  type        = list(any)
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "security_groups" {
  description = "Security groups to attach to the ALB"
  type        = list(string)
}

variable "shared_access_log_bucket" {
  type = string
}

# Type constraint catches misuse at plan time.
variable "ssl_cert_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}
