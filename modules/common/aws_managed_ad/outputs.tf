# outputs.tf
# Part of the output value definitions module.

output "id" {
  description = "The ID of the AWS managed AD"
  value       = "${aws_directory_service_directory.directory_service.id}"
}

output "access_url" {
  description = "The access URL for the directory, such as http://alias.awsapps.com."
  value       = "${aws_directory_service_directory.directory_service.access_url}"
}

output "dns_ip_addresses" {
  description = "A list of IP addresses of the DNS servers for the directory or connector."
  value       = ["${aws_directory_service_directory.directory_service.dns_ip_addresses}"]
}

output "security_group_id" {
  description = "The ID of the security group created by the directory."
  value       = "${aws_directory_service_directory.directory_service.security_group_id}"
}

output "aws_iam_managed_policy_arn" {
  value = "${aws_iam_policy.domain_computer_policy.arn}"
}

output "aws_iam_instance_profile_name" {
  value = "${aws_iam_instance_profile.domain_computer_profile.name}"
}

output "aws_ssm_document_name" {
  value = "${aws_ssm_document.ssm_document.name}"
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}-${timestamp()}"
}
