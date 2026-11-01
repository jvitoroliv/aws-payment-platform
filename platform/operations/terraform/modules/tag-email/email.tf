resource "aws_ses_domain_identity" "app_email" {
  domain = var.email_domain
}

# Create an output containing DNS record info for SES domain verification
# Can't create the record directly as the two AWS regions would conflict
output "ses_verification_record" {
  description = "SES domain verification record details"
  value = {
    name    = "_amazonses.${var.email_domain}"
    type    = "TXT"
    ttl     = "600"
    records = [aws_ses_domain_identity.app_email.verification_token]
  }
}

resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = "default-rule-set-${var.environment}"
}

resource "aws_ses_receipt_rule" "store_incoming_emails_in_s3" {
  name          = "${var.environment}-${var.aws_region}-store-incoming-emails-in-s3"
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
  recipients    = [aws_ses_domain_identity.app_email.domain]
  enabled       = true
  scan_enabled  = false

  s3_action {
    bucket_name = var.incoming_mail_bucket_id
    position    = 1
  }
}

resource "aws_ses_identity_notification_topic" "bounce" {
  topic_arn                = aws_sns_topic.email_bounce_notification.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.app_email.domain
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "complaint" {
  topic_arn                = aws_sns_topic.email_complaint_notification.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.app_email.domain
  include_original_headers = true
}

resource "aws_sns_topic" "cloudwatch_alarm_notification" {
  name = "${var.environment}-${var.aws_region}-cloudwatch_alarm_notification"
}

resource "aws_sns_topic" "email_bounce_notification" {
  name = "${var.environment}-${var.aws_region}-email-bounce-notification"
}

resource "aws_sns_topic_subscription" "email_bounce_sqs_target" {
  topic_arn = aws_sns_topic.email_bounce_notification.arn
  protocol  = "sqs"
  endpoint  = var.email_bounce_queue_arn
}

resource "aws_sns_topic" "email_complaint_notification" {
  name = "${var.environment}-${var.aws_region}-email-complaint-notification"
}

resource "aws_sns_topic_subscription" "email_complaint_sqs_target" {
  topic_arn = aws_sns_topic.email_complaint_notification.arn
  protocol  = "sqs"
  endpoint  = var.email_bounce_queue_arn
}
