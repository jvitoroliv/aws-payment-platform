# variables.tf
# Part of the input variable declarations module.

variable "additional_alb_security_groups" {
  description = "List of additional security groups to attach to the internal ALB"
  type        = list(string)
  default     = []
}
# Defaults work for standard deployments.
variable "api_internal_fqdns_name" {
  description = "The internal DNS name for the Payment Scheduler API"
  type        = string
}
variable "api_internal_whitelist" {
  description = "List of CIDR blocks to allow access to the internal API"
  type        = list(string)
}
variable "app_id" {
  description = "The LogicGate application ID"
  type        = string
}
variable "autoscaling_max_capacity" {
  type    = number
  default = 2
}
# Input validation ensures callers provide sane values.
variable "autoscaling_min_capacity" {
  type    = number
  default = 2
}
variable "aws_account_id" {
  type = string
}
variable "aws_private_subnet_ids" {
  description = "List of private subnet IDs to deploy resources in"
  type        = list(string)
}
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}
variable "aws_vpc_id" {
  description = "ID of the VPC to deploy resources in"
  type        = string
}
variable "container_host_port" {
  description = "The port on the Fargate host mapped to the container port"
  type        = number
  default     = 8001
}
variable "container_image" {
  description = "The Payment Scheduler container image to deploy"
  type        = string
}
variable "container_port" {
  description = "The port that the container listens on"
  type        = number
  default     = 8001
}
variable "crowdstrike_sensor_version" {
  description = "The version of the CrowdStrike sensor to use"
  type        = string
}
variable "datadog_api_key" {
  description = "The Datadog API key stored in AWS Secrets Manager"
  type        = string
}
variable "datadog_image" {
  type    = string
  default = "registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.46.0"
}
# Defaults are production-safe; override per environment.
variable "datadog_tag_cardinality" {
  type    = string
  default = "orchestrator"
}
variable "dns_zone_id" {
  type = string
}
variable "environment" {
  type = string
}
variable "health_check_enabled" {
  type    = bool
  default = true
}
variable "health_check_healthy_threshold" {
  type    = number
  default = 2
}
variable "health_check_interval" {
  type    = number
  default = 10
}
variable "health_check_matcher" {
  type    = number
  default = 200
}
variable "health_check_path" {
  type    = string
  default = "/healthcheck"
}
variable "health_check_port" {
  type    = string
  default = "traffic-port"
}
# Type constraint catches misuse at plan time.
variable "health_check_timeout" {
  type    = number
  default = 5
}
variable "health_check_unhealthy_threshold" {
  type    = number
  default = 2
}
variable "internal_cidr_block" {
  description = "The CIDR block of the internal VPC"
  type        = string
}
variable "listener_targets" {
  description = "List of listener target mappings for the internal ALB"
  type = list(object({
    lb_port       = number
    lb_proto      = string
    be_port       = number
    be_proto      = string
    lb_ssl_policy = string
  }))
}
variable "load_balancer_idle_timeout" {
  type    = number
  default = 60
}
variable "log_lambda_arn" {
  type = string
}
variable "log_script_filter_count" {
  description = "Set to 1 to enable log subscription filter for script logs"
  type        = number
  default     = 1
}
variable "shared_access_log_bucket" {
  type = string
}
variable "task_definition_cpu" {
  type = number
}
variable "task_definition_memory" {
  type = number
}
variable "vpc_cidr_bridge" {
  type = string
}
variable "web_ssl_cert_arn" {
  type = string
}
variable "endpoint_security_cid" {
  type = string
}
variable "artifactory_secret_arn" {
  type = string
}
