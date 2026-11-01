# variables.tf
# Part of the input variable declarations module.

variable "app_version" {
  type = string
}
variable "autoscaling_max_capacity" {
  type    = number
  default = 2
}
variable "autoscaling_min_capacity" {
  type    = number
  default = 2
}
variable "aws_private_subnet_ids" {
  type = list(string)
}
# Type constraint catches misuse at plan time.
variable "aws_region" {
  type = string
}
variable "aws_vpc_id" {
  type = string
}
variable "dns_zone_id" {
  type = string
}
# Defaults are production-safe; override per environment.
variable "environment" {
  type = string
}
variable "load_balancer_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
variable "task_definition_cpu" {
  type    = number
  default = 2048
}
variable "task_definition_memory" {
  type    = number
  default = 4096
}
variable "web_ssl_cert_arn" {
  type = string
}
variable "ingress_allowlists" {
  description = "List of allowlist names to pull security group IDs from and attach to the ALB. Allowlists are managed in shared-terraform repo."
  type        = list(string)
  default     = []
}
