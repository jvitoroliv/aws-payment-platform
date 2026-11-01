# variables.tf
# Part of the input variable declarations module.

# Type constraint catches misuse at plan time.
variable "billingid" {
  type = "string"
}

variable "compliance" {
  type = "string"
}

variable "dataclass" {
  type = "string"
}

# Defaults are production-safe; override per environment.
variable "drtier" {
  type = "string"
}

variable "environment" {
  type = "string"
}

variable "lob" {
  type = "string"
}

variable "owner" {
  type = "string"
}

variable "projectname" {
  type = "string"
}

variable "approle" {
  type = "string"
}

variable "app_id" {
  type = "string"
}

variable "ostype" {
  type = "string"
}
variable "application" {
  type = "string"
}

variable "finame" {
  type = "string"
  default = "shrd"
}