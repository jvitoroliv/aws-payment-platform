# outputs.tf
# Part of the output value definitions module.

output "primary_app_file_storage" {
  value = module.s3_replication.primary_app_file_storage
}

output "secondary_app_file_storage" {
  value = module.s3_replication.secondary_app_file_storage
}
