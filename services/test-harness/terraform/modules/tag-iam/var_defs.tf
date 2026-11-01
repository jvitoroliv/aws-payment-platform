# var_defs.tf
# Manages var_defs Terraform configuration resources.

# Documented in the module README with accepted ranges.
variable "environment" {}

variable "aws_region" {}

variable "aws_account_number" {}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC Provider ID (e.g., EKS1234567890ABCDEF)"
  type        = string
  default     = ""
}
