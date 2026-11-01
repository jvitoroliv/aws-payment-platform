aws_managed_ad
==============

Creates an AWS managed Active Directory service, SSM Documents to auto-domain join, and Instance IAM Profile along with a managed IAM Policy

# Resource

This module creates the following resources:

* An AWS Manged Directory Service
* An SSM Document that can be used by instances for secure domain auto-join
* A Managed IAM Policy allowing the association with the created SSM document
* A base IAM Role and Instance Profile that can be given directly to instances to allow auto domain join


# Variables

* **dependencies**: A list of TF resources to depend on (see: https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607)
* **directory_name**: the FQDN of the domain
* **directory_type**: the type of directory service. Only. "MicrosoftAD" is supported.
* **directory_edition**: the size of the AD (Standard or Enterprise)
* **directory_password**: the admin password to be used when creating the directory
* **vpc_id"**: the identifier for the VPC of where the directory service will reside
* **subnet_ids**: a list of exactly 2 subnet IDs for where the domain controllers to be placed
* **ec2_ssm_domain_join_ou**: The OU for where computer objects should join to when using the SSM auto-join
* **tags**: a map of tags to apply to resources


# Outputs

* **id**: The ID of the AWS Managed Directory Service
* **access_url**: The access URL for the managed directory service
* **dns_ip_addresses**: The IP addresses assigned to the domain controllers
* **security_group_id**: The ID of the security group created by the managed directory service
* **aws_iam_managed_policy_arn**: The ARN associated with the managed policy that can be used in other roles
* **aws_iam_iinstance_profile_name**: The name of the created AWS instance profile that can be assigned to instances for auto-join of the domain
* **aws_ssm_document_name**: The name of the SSM Document that can be used for auto-joining the domain
* **depended_on**: list of resources this module depended on (see: https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607)
