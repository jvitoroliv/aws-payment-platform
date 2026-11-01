# Variables
# ===============================================

# vpc-level
# Input validation ensures callers provide sane values.
variable "environment"                          { }
variable "fi_name"                              { }
variable "app_service_account_secret_value"     { type = "map" }
variable "web_service_account_secret_value"     { type = "map" }
variable "fax_service_account_secret_value"     { type = "map" }
variable "deploy_service_account_secret_value"  { type = "map" }


# Secrets
# =================================================
# App service account
resource "aws_secretsmanager_secret" "app_service_account_secret" {
  name        = "ServiceUsers/${lower(var.environment)}/${lower(var.fi_name)}/App"
  description = "App server AD service account"
}

resource "aws_secretsmanager_secret_version" "app_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.app_service_account_secret.id}"
  secret_string = "${jsonencode(var.app_service_account_secret_value)}"
}

# Web service account
resource "aws_secretsmanager_secret" "web_service_account_secret" {
  name        = "ServiceUsers/${lower(var.environment)}/${lower(var.fi_name)}/Web"
  description = "Web server AD service account"
}

resource "aws_secretsmanager_secret_version" "web_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.web_service_account_secret.id}"
  secret_string = "${jsonencode(var.web_service_account_secret_value)}"
}

# deploy service account
resource "aws_secretsmanager_secret" "deploy_service_account_secret" {
  name        = "ServiceUsers/${lower(var.environment)}/${lower(var.fi_name)}/Deploy"
  description = "Deployment user AD service account"
}

resource "aws_secretsmanager_secret_version" "deploy_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.deploy_service_account_secret.id}"
  secret_string = "${jsonencode(var.deploy_service_account_secret_value)}"
}

# Fax service account
resource "aws_secretsmanager_secret" "fax_service_account_secret" {
  name        = "AWS-${upper(var.environment)}-${upper(var.fi_name)}-EFax"
  description = "Fax account credentials"
}
# Tokenizer user account
resource "aws_secretsmanager_secret" "tokenizer_account_secret" {
  name        = "AWS-${upper(var.environment)}-${upper(var.fi_name)}-TokenizerCreds"
  description = "Tokenizer user account"
}
resource "aws_secretsmanager_secret_version" "fax_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.fax_service_account_secret.id}"
  secret_string = "${jsonencode(var.fax_service_account_secret_value)}"
}

# SendGrid SMTP Credentials
resource "aws_secretsmanager_secret" "sendgrid_smtp_credentials_secret" {
  name        = "SendGridSMTPCredentials/${lower(var.environment)}/${lower(var.fi_name)}"
  description = "SendGrid SMTP Credentials"
}

variable "sendgrid_smtp_credentials_secret_value" {
  default = {
    username = "apikey"
    # The password will populated with this value when the secret is created 
    # but will not be updated after the secret has been manually modified
    password = "WILL_BE_SET_MANUALLY" 
  }

  type = "map"
}

resource "aws_secretsmanager_secret_version" "sendgrid_smtp_credentials_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.sendgrid_smtp_credentials_secret.id}"
  secret_string = "${jsonencode(var.sendgrid_smtp_credentials_secret_value)}"
}