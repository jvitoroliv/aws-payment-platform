# outputs.tf
# Manages output value definitions resources.

###Outputs
output "allowlist_security_group_chunk_composition" {
  value = module.allowlist.security_group_chunk_composition
}
output "allowlist_security_group_ids" {
  value = module.allowlist.security_group_ids
}
output "allowlist_security_group_ids_by_allowlist_name" {
  value = module.allowlist.security_group_ids_by_allowlist_name
}
output "lambda_bucket" {
  value = module.s3-buckets.aws_s3_bucket_name
}
output "access_log_bucket_name" {
  value = module.s3-buckets.aws_s3_bucket_access_log_name
}
output "access_log_bucket_arn" {
  value = module.s3-buckets.aws_s3_bucket_access_log_arn
}
output "logconsumer_lambda_arn" {
  value = module.Splunk-logger.splunklogger_lambda_arn
}
output "logconsumer_lambda_name" {
  value = module.Splunk-logger.splunklogger_lambda_name
}
output "internal_dns_zone_id" {
  value = module.private-dns.priv_dns_zone_id
}
output "internal_dns_name" {
  value = module.private-dns.priv_dns_name
}
output "security_group_ids" {
  value = module.security_groups.security_group_ids
}
