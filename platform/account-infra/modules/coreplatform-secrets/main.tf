# Variables
# =================================================
# Type constraint catches misuse at plan time.
variable "environment"                     { }
variable "ad_service_account_secret_value" { }
variable "db_service_account_secret_value" { type = "map" }
variable "sms_account_secret_value" {
  default = {
    Token = "WILL_BE_SET_MANUALLY"
  }
  type = "map"
}

# Secrets
# =================================================
# AD admin password
resource "aws_secretsmanager_secret" "ad_password_secret" {
  name        = "${lower(var.environment)}/adpassword"
  description = "AD admin password"
}

resource "aws_secretsmanager_secret_version" "ad_password_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.ad_password_secret.id}"
  secret_string = "WILL_BE_SET_MANUALLY"
}

# AD join service username
resource "aws_secretsmanager_secret" "ad_service_account_secret" {
  name        = "${lower(var.environment)}/ad_service_account"
  description = "AD join service user username"
}

resource "aws_secretsmanager_secret_version" "ad_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.ad_service_account_secret.id}"
  secret_string = "${var.ad_service_account_secret_value}"
}

# AD join service user password
resource "aws_secretsmanager_secret" "ad_service_password_secret" {
  name        = "${lower(var.environment)}/ad_service_password"
  description = "AD join service user password"
}

resource "aws_secretsmanager_secret_version" "ad_service_password_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.ad_service_password_secret.id}"
  secret_string = "WILL_BE_SET_MANUALLY"
}

# Db service account
resource "aws_secretsmanager_secret" "db_service_account_secret" {
  name        = "ServiceUsers/${lower(var.environment)}/ALLFIS/Db"
  description = "Db service account"
}

resource "aws_secretsmanager_secret_version" "db_service_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.db_service_account_secret.id}"
  secret_string = "${jsonencode(var.db_service_account_secret_value)}"
}

# Active crypto keys
resource "aws_secretsmanager_secret" "activekeys_secret" {
  name        = "ActiveKeys/${lower(var.environment)}"
  description = "Active crypto keys"
}

variable "activekeys_secret_value" {
  default = {
    FinservActiveKey = "A"  # Default to this value, it may need to be manually changed later
  }

  type = "map"
}

resource "aws_secretsmanager_secret_version" "activekeys_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.activekeys_secret.id}"
  secret_string = "${jsonencode(var.activekeys_secret_value)}"
}

# SMS user account
resource "aws_secretsmanager_secret" "sms_account_secret" {
  name        = "AWS-${upper(var.environment)}-ALLFIS-SmsAuthToken"
  description = "SMS user account"
}

resource "aws_secretsmanager_secret_version" "sms_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.sms_account_secret.id}"
  secret_string = "${jsonencode(var.sms_account_secret_value)}"
}

# Secure ADO build server
resource "aws_secretsmanager_secret" "buildserver_secret" {
  name        = "BuildServer/${lower(var.environment)}"
  description = "Secure ADO build server"
}

# Defaults are production-safe; override per environment.
variable "buildserver_secret_value" {
  default = {
    Url                  = "WILL_BE_SET_MANUALLY" # Azure ADO URL
    PAT                  = "WILL_BE_SET_MANUALLY" # Personal access token created in ADO 
  }

  type = "map"
}

resource "aws_secretsmanager_secret_version" "buildserver_secret_value_version" {
  secret_id     = "${aws_secretsmanager_secret.buildserver_secret.id}"
  secret_string = "${jsonencode(var.buildserver_secret_value)}"
}
