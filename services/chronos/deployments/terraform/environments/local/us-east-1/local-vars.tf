# local-vars.tf
# Part of the local-vars Terraform configuration module.

variable "active_region" {
  type    = string
  default = "__local__"
}

variable "artifact_bucket" {
  type    = string
  default = "local-us-east-1-app-artifacts-lambda"
}

variable "artifact_path" {
  type    = string
  default = "chronos"
} # Absolute path to the directory containing the binaries

variable "aws_account_number" {
  type    = string
  default = "000000000000"
}

# Defaults are production-safe; override per environment.
variable "aws_endpoint" {
  type    = string
  default = "0.0.0.0"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "local"
}

variable "mongo_uri" {
  type = string
  #  default = "__NONE__"
  default = "mongodb://localhost:27019"
}

variable "mongo_username" {
  type    = string
  default = "__NONE__"
}

variable "subnet_ids" {
  type    = list(any)
  default = []
}
