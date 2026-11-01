# output.tf
# Manages output Terraform configuration resources.

output "chronos_billable_entity_cycling_sns_topic_arn" {
  value = module.chronos_billable_entity_cycling_sns_topic.sns_topic_arn
}

output "chronos_billable_entity_late_fee_sns_topic_arn" {
  value = module.chronos_billable_entity_late_fee_sns_topic.sns_topic_arn
}

output "chronos_billable_entity_delinquency_changed_sns_topic_arn" {
  value = module.chronos_billable_entity_delinquency_changed_sns_topic.sns_topic_arn
}

output "api_invoke_url" {
  value = module.chronos_api.invoke_url
}
