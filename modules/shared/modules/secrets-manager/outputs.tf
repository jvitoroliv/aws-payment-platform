# outputs.tf
# Part of the output value definitions module.

output "secret_id" {
  value       = aws_secretsmanager_secret.secret.id
  description = "The ARN of the secret"
}

output "replica_status" {
  value       = length(aws_secretsmanager_secret.secret.replica) > 0 ? tolist(aws_secretsmanager_secret.secret.replica)[0].status : "No replica"
  description = "Status can be InProgress, Failed, or InSync."
}

output "version_id" {
  value       = aws_secretsmanager_secret_version.secret.version_id
  description = "The unique identifier of the version of the secret."
}

output "secret" {
  value       = aws_secretsmanager_secret_version.secret.id
  description = "A pipe delimited combination of secret ID and version ID."
}

output "rotation_enabled" {
  value       = var.secret_rotation ? aws_secretsmanager_secret_rotation.secret[0].rotation_enabled : false
  description = "Indicates whether automatic rotation is enabled for the secret."
}
