# cloudwatch.tf
# Part of the CloudWatch alarms and dashboards module.

resource "aws_cloudwatch_event_rule" "monthly-report" {
  name                = "${var.environment}-${var.aws_region}-monthly-report"
  schedule_expression = var.monthly_cron
  description         = "Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "monthly-report-target" {
  rule  = aws_cloudwatch_event_rule.monthly-report.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"GenerateReport\",\"parameters\": {\"period\": \"monthly\"}}"
}

resource "aws_cloudwatch_event_rule" "quarterly-report" {
  name                = "${var.environment}-${var.aws_region}-quarterly-report"
  schedule_expression = var.quarterly_cron
  description         = "Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "quarterly-report-target" {
  rule  = aws_cloudwatch_event_rule.quarterly-report.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"GenerateReport\",\"parameters\": {\"period\": \"quarterly\"}}"
}

resource "aws_cloudwatch_event_rule" "partner-daily-reports" {
  name                = "${var.environment}-${var.aws_region}-partner-daily-reports"
  schedule_expression = "cron(0 7 * * ? *)" // 2 AM EST
  description         = "Run every day at 7:00 UTC | 2:00 EST -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}


resource "aws_cloudwatch_event_target" "partner-daily-reports-target" {
  rule  = aws_cloudwatch_event_rule.partner-daily-reports.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"GenerateReport\",\"parameters\": {\"period\": \"daily\", \"fiNumber\": \"1984\"}}"
}

resource "aws_cloudwatch_event_target" "downtime-requeue-target" {
  rule  = "${var.environment}-${var.aws_region}-every-5-minutes-seg-2"
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"RequeueDiversions\"}"
}

resource "aws_cloudwatch_event_rule" "sla-monthly-report" {
  name                = "${var.environment}-${var.aws_region}-sla-monthly-report"
  schedule_expression = "cron(0 6 1 * ? *)"
  description         = "Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "sla-monthly-report-target" {
  rule  = aws_cloudwatch_event_rule.sla-monthly-report.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"SLAReports\"}"
}

resource "aws_cloudwatch_event_rule" "expire-auth-overrides" {
  name                = "${var.environment}-${var.aws_region}-expire-auth-overrides"
  schedule_expression = "cron(2 0 ? * * *)"
  description         = "Run daily at 12:02 midnight -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "expire-auth-overrides" {
  rule  = aws_cloudwatch_event_rule.expire-auth-overrides.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"ExpireAuthOverrides\"}"
}

resource "aws_cloudwatch_event_rule" "end-of-day" {
  name                = "${var.environment}-${var.aws_region}-end-of-day"
  schedule_expression = "cron(0 19 ? * * *)"
  description         = "Run every day at 19:00 UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

/*
Splitting every-5 into two segments. Aws limits each event rule target to 5 at a max.
When max is hit Error: Creating CloudWatch Event Target failed: LimitExceededException: The requested resource exceeds the maximum number allowed.
Create new event rule with same schedule, give unq classification and name and assign target to new event rule
*/

resource "aws_cloudwatch_event_rule" "every-5-minutes" {
  name                = "${var.environment}-${var.aws_region}-every-5-minutes"
  schedule_expression = "rate(5 minutes)"
  description         = "Run every 5 minutes -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_rule" "every-5-minutes-seg-2" {
  name                = "${var.environment}-${var.aws_region}-every-5-minutes-seg-2"
  schedule_expression = "rate(5 minutes)"
  description         = "Run every 5 minutes -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_rule" "every-30-minutes" {
  name                = "${var.environment}-${var.aws_region}-every-30-minutes"
  schedule_expression = "rate(30 minutes)"
  description         = "Run every 30 minutes -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "poll-mastercard" {
  rule  = aws_cloudwatch_event_rule.every-30-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PollMasterCard\"}"
}

resource "aws_cloudwatch_event_target" "check-pending-auths" {
  rule  = aws_cloudwatch_event_rule.every-5-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckPendingAuths\"}"
}

resource "aws_cloudwatch_event_target" "check-company-limits" {
  rule  = aws_cloudwatch_event_rule.every-5-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckLimits\"}"
}

resource "aws_cloudwatch_event_target" "check-bin-limits" {
  rule  = aws_cloudwatch_event_rule.end-of-day.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckBinLimits\"}"
}

resource "aws_cloudwatch_event_rule" "daily-statementszip-created" {
  name                = "${var.environment}-${var.aws_region}-daily-statementszip-created"
  schedule_expression = "cron(0 14 ? * * *)"
  description         = "Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "daily-statementszip-created-target-0010" {
  count = var.environment == "prod" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.daily-statementszip-created.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckStatementsZipCreated\", \"Parameters\": { \"FI\": \"0010\"} }"
}

resource "aws_cloudwatch_event_target" "daily-statementszip-created-target-0022" {
  count = var.environment == "test" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.daily-statementszip-created.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckStatementsZipCreated\", \"Parameters\": { \"FI\": \"0022\"} }"
}

resource "aws_cloudwatch_event_target" "daily-statementszip-created-target-0033" {
  count = 1
  rule  = aws_cloudwatch_event_rule.daily-statementszip-created.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CheckStatementsZipCreated\", \"Parameters\": { \"FI\": \"0033\"} }"
}

resource "aws_cloudwatch_event_rule" "close-chargeback-rule" {
  name                = "${var.environment}-${var.aws_region}-close-chargeback-rule"
  schedule_expression = "cron(30 10 ? * * *)"
  description         = "Run daily -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "close-chargeback-target" {
  rule  = aws_cloudwatch_event_rule.close-chargeback-rule.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CloseChargebacks\",\"parameters\": {}}"
}

locals {
  visa_eod_schedule = "cron(0 4 * * ? *)" // 23 EST
  visa_eod_input    = var.environment == "prod" ? "{\"type\": \"VisaClearingEndOfDay\",\"parameters\": {}}" : "{\"type\": \"VisaClearingEndOfDay\",\"parameters\": {\"disableBatchValidation\": \"true\"}}"

  # Trigger multiple times per day and mute alerting in TEST to support regression testing
  test_visa_eod_schedule = "cron(0 4-16 * * ? *)" // 23-11 EST
  test_visa_eod_input    = "{\"type\": \"VisaClearingEndOfDay\",\"parameters\": {\"disableBatchValidation\": \"true\"}}"
}

resource "aws_cloudwatch_event_rule" "visa_clearing_eod" {
  name                = "${var.environment}-${var.aws_region}-visa-clearing-end-of-day"
  schedule_expression = var.environment == "test" ? local.test_visa_eod_schedule : local.visa_eod_schedule
  description         = "Run daily -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "visa_clearing_eod" {
  rule  = aws_cloudwatch_event_rule.visa_clearing_eod.name
  arn   = var.scheduled_event_queue_arn
  input = var.environment == "test" ? local.test_visa_eod_input : local.visa_eod_input
}

resource "aws_cloudwatch_event_rule" "post_direct_debit_payments" {
  name                = "${var.environment}-${var.aws_region}-post-direct-debit-payments"
  schedule_expression = "cron(0 23 * * ? *)"
  description         = "Run daily -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_rule" "post_direct_debit_payments_partner_a" {
  name                = "${var.environment}-${var.aws_region}-post-direct-debit-payments-partner_a"
  schedule_expression = "cron(0 7 * * ? *)"
  description         = "Run daily at 3am Eastern/5am UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "post_direct_debit_payments" {
  rule  = aws_cloudwatch_event_rule.post_direct_debit_payments.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PostDirectDebitPayments\",\"Parameters\": {\"FI\":\"0010\"}}"
}

resource "aws_cloudwatch_event_target" "post_direct_debit_payments_0033" {
  count = 1
  rule  = aws_cloudwatch_event_rule.post_direct_debit_payments_partner_a.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PostDirectDebitPayments\",\"Parameters\": {\"FI\":\"0033\"}}"
}

resource "aws_cloudwatch_event_target" "file-arrival-heartbeat" {
  rule  = aws_cloudwatch_event_rule.every-5-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"FileArrivalHeartbeat\"}"
}

resource "aws_cloudwatch_event_rule" "poll_direct_debit" {
  name                = "${var.environment}-${var.aws_region}-poll-direct-debit"
  schedule_expression = "cron(0 21 * * ? *)"
  description         = "Run every day at 21:00 UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "poll_direct_debit" {
  rule  = aws_cloudwatch_event_rule.poll_direct_debit.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PollDirectDebit\",\"Parameters\": {\"FI\":\"0010\"}}"
}

resource "aws_cloudwatch_event_rule" "post_direct_debit_payments_0022" {
  count               = var.environment == "test" ? 1 : 0
  name                = "${var.environment}-${var.aws_region}-post-direct-debit-payments-0022"
  schedule_expression = "cron(0 23 * * ? *)"
  description         = "Run daily -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "post_direct_debit_payments_0022" {
  count = var.environment == "test" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.post_direct_debit_payments_0022[0].name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PostDirectDebitPayments\",\"Parameters\": {\"FI\":\"0022\"}}"
}

resource "aws_cloudwatch_event_rule" "poll_direct_debit_0022" {
  count               = var.environment == "test" ? 1 : 0
  name                = "${var.environment}-${var.aws_region}-poll-direct-debit-0022"
  schedule_expression = "cron(0 21 * * ? *)"
  description         = "Run every day at 21:00 UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "poll_direct_debit_0022" {
  count = var.environment == "test" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.poll_direct_debit_0022[0].name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"PollDirectDebit\",\"Parameters\": {\"FI\":\"0022\"}}"
}

resource "aws_cloudwatch_event_target" "generate-statement-zips" {
  rule  = aws_cloudwatch_event_rule.every-30-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"GenerateStatementZips\"}"
}

resource "aws_cloudwatch_event_target" "reset-accumulators-rule-target" {
  count = var.environment == "dev" ? 0 : 1
  rule  = aws_cloudwatch_event_rule.every-5-minutes.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"ExpireAuths\",\"Parameters\": {\"Reset\": \"true\"}}"
}

resource "aws_cloudwatch_event_rule" "compare-balances-rule" {
  name                = "${var.environment}-${var.aws_region}-compare-balances-rule"
  schedule_expression = "cron(0 13 * * ? *)"
  description         = "Run every day at 13:00 UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "compare-balances-rule-target" {
  rule  = aws_cloudwatch_event_rule.compare-balances-rule.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"CompareChronosTagBalances\"}"
}

resource "aws_cloudwatch_event_rule" "partner-company-balance-adjustment-rule" {
  name                = "${var.environment}-${var.aws_region}-partner-company-balance-adjustment-rule"
  schedule_expression = "cron(0 5 * * ? *)"
  description         = "Run every day at 5:00 UTC -- Managed By Terraform"
  state               = local.is_enabled
  role_arn            = aws_iam_role.cloudwatch_role.arn
}

resource "aws_cloudwatch_event_target" "partner-company-balance-adjustment-rule-target" {
  rule  = aws_cloudwatch_event_rule.partner-company-balance-adjustment-rule.name
  arn   = var.scheduled_event_queue_arn
  input = "{\"type\": \"NAFCompanyBalanceAdjustment\"}"
}
