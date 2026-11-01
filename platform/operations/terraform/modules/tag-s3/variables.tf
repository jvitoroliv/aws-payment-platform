# variables.tf
# Part of the input variable declarations module.

variable "environment" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "aws_account_number" {
  type = string
}
variable "image_url" {
  type = string
}