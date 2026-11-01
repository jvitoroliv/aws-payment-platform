# variables.tf
# Manages input variable declarations resources.

variable "service_name" {
  type        = string
  description = "(Required) ECS service name"
}

variable "target_value" {
  type        = number
  description = "(Required) Target value for the metric."
}

variable "queue_name" {
  type        = string
  description = "(Required) SQS queue name for the autoscaling policy"
}

variable "cluster_name" {
  type        = string
  description = "(Required) ECS cluster name"
}

variable "max_capacity" {
  type        = number
  default     = 4
  description = "Max capacity of the scalable target."
}

variable "min_capacity" {
  type        = number
  default     = 1
  description = "Min capacity of the scalable target."
}

variable "scale_in_cooldown" {
  type        = number
  default     = 300
  description = "Amount of time, in seconds, after a scale in activity completes before another scale in activity can start."
}

# Documented in the module README with accepted ranges.
variable "scale_out_cooldown" {
  type        = number
  default     = 60
  description = "Amount of time, in seconds, after a scale out activity completes before another scale out activity can start."
}
