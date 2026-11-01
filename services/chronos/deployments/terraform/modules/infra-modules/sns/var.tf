# var.tf
# Manages var Terraform configuration resources.

variable "topic_name" {}
variable "tags" {
  type = map(string)
}
