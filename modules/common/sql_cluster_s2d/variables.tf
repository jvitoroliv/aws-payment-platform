# variables.tf
# Part of the input variable declarations module.


variable "automation_scripts_bucket" { }
variable "ami"                       { }
# Input validation ensures callers provide sane values.
variable "instance_type"             { }
variable "root_vol_size"             { }
variable "key_name"                  { }
variable "svr_name_prefix"           {
  description = "Name prefix used in multiple resources."
}
variable "name_format" {
  description = "Instances' Name tag. This string is formatted with the # of server."
}
variable "hostname_format" {
  description = "Instances' hostname as well as its 'Hostname' tag. This string is formatted with the # of server."
}
# Documented in the module README with accepted ranges.
variable "win_cluster_name" {
  description = "Network name for the computer object in Active Directory for the Windows Failover Cluster."
}
variable "sql_cluster_name" {
  description = "Network name for the computer object in Active Directory for the SQL Failover Cluster Role."
}

variable "inbound_security_group_ids" { type = "list" }

# Type constraint catches misuse at plan time.
variable "subnet_ids"                { type = "list" }
variable "tags"                      { type = "map" }
variable "ad_password_secrets_arn"   {
  description = "Secrets Manager ARN that contains the AD admin password."
}
# Defaults are production-safe; override per environment.
variable "ad_username_secrets_arn"  {
  description = "Secrets Manager ARN that contains the AD service accountusername."

 }

variable "sql_svcacct_creds_secrets_arn" {
  description = "Secrets Manager ARN that contains the SQL service account username & password."
}
#TODO: remove after gMSA support for ECS is available
variable "sql_login_creds_secrets_arn" {
  description = "Secrets Manager ARN that contains the SQL login username & password."
}

variable "netbios_domain_name"       { }
variable "domain_dns_name"           { }
variable "oupath"                    { }

variable "enc_fi"                    { }
variable "environment"               { }
#variable "dns_server_addresses"      { }

variable "num_of_secondary_nodes"       { default = 2 }

variable "ebs_kms_key_id"               { default = "" }

variable "default_pool_ebs_vols_size"   { default = 10 }
variable "default_pool_ebs_vols_type"   { default = "gp2" }
variable "default_pool_ebs_vols_iops"   { default = "" }
variable "fci_pool_ebs_vols_size"       { default = 10 }
variable "fci_pool_ebs_vols_type"       { default = "gp2" }
variable "fci_pool_ebs_vols_iops"       { default = "" }
variable "coreplatform_pool_ebs_vols_size" { default = 10 }
variable "coreplatform_pool_ebs_vols_type" { default = "io1" }
variable "coreplatform_pool_ebs_vols_iops" { default = "4000" }
variable "archive_pool_ebs_vols_size"   { default = 10 }
variable "archive_pool_ebs_vols_type"   { default = "gp2" }
variable "archive_pool_ebs_vols_iops"   { default = "" }
variable "backup_pool_ebs_vols_size"    { default = 10 }
variable "backup_pool_ebs_vols_type"    { default = "st1" }
variable "backup_pool_ebs_vols_iops"    { default = "" }

variable "sql_server_iso_bucket"        { }
variable "sql_server_backups_bucket"    { }
variable "coreplatform_artifacts_bucket"   { }
#variable "runtime_tag"                  { default = "off=(M-F,21);on=(M-F,7);tz=est" }

variable "ec2on_tag" {
  default = "on=(M-F,7);tz=est"
}

variable "ec2off_tag" {
  default = "off=(M-F,21);tz=est"
}

variable "executionTimeout"             { default = "3600" }