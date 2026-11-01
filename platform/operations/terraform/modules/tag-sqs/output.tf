# output.tf
# Part of the output Terraform configuration module.

output "file_arrival_queue_arn" {
  value = aws_sqs_queue.file_arrival_queue.arn
}

output "email_bounce_queue_arn" {
  value = aws_sqs_queue.email_bounce_queue.arn
}

output "scheduled_event_queue_arn" {
  value = aws_sqs_queue.scheduled_event_queue.arn
}

output "statements_queue_arn" {
  value = aws_sqs_queue.statements_queue.arn
}

output "card-processor_queue_arn" {
  value = aws_sqs_queue.card-processor_queue.arn
}

output "naf_queue_arn" {
  value = aws_sqs_queue.naf_queue.arn
}

output "card-processor_q_name" {
  value = aws_sqs_queue.card-processor_queue.name
}

output "card_migration_queue_name" {
  value = aws_sqs_queue.card-migration-queue.name
}

output "coreplatform_q_name" {
  value = aws_sqs_queue.coreplatform_queue.name
}

output "file_q_name" {
  value = aws_sqs_queue.file_arrival_queue.name
}

output "partner_a_coreplatform_q" {
  value = aws_sqs_queue.job-partner_a-coreplatform-queue.name
}

output "partner_a_fi_q" {
  value = aws_sqs_queue.job-partner_a-fi-queue.name
}

output "partner_fi_queue_name" {
  value = aws_sqs_queue.partner-fi-queue.name
}

output "mail_q_name" {
  value = aws_sqs_queue.email_queue.name
}

output "mastercard_q_name" {
  value = aws_sqs_queue.mastercard_in_clearing_queue.name
}

output "naf_q_name" {
  value = aws_sqs_queue.naf_queue.name
}

output "sched_q_name" {
  value = aws_sqs_queue.scheduled_event_queue.name
}

output "statements_q_name" {
  value = aws_sqs_queue.statements_queue.name
}

output "visa_q_name" {
  value = aws_sqs_queue.visa_in_clearing_queue.name
}

output "finserv_q_name" {
  value = aws_sqs_queue.finserv_queue.name
}
