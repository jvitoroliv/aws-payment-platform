# locals.tf
# Manages local value computations resources.

locals {
  app_script_storage_bucket_name = "${var.environment}-${var.aws_region}-app-artifacts-scripts"
  incoming_mail_bucket_name      = "${var.environment}-${var.aws_region}-app-artifacts-mail"
  static_content_bucket_name     = "${var.environment}-${var.aws_region}-images.${var.image_url}"
}
