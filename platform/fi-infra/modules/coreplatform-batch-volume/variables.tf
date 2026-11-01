# variables.tf
# Part of the input variable declarations module.

variable "instance_id_number" {
  description = "A 3 digit number for the hostname of the machine from 004 to 999. Make sure you select something unique based on the other entry points or it will not work"
 }
variable "ec2on_tag" {
  default = "on=(M-F,7);tz=est"
  description = "The days and times you want the instance to be STARTED by the custodian auto start-stop process."
}
variable "ec2off_tag" {
  default = "off=(M-F,21);tz=est" 
  description = "The days and times you want the instance to be STOPPED by the devops auto start-stop process."
}
variable "volume_size" {
  default = 350 
  description = "The Volume size to be used for the data volume"
}
variable "volume_type" {
  default = "gp3" 
  description = "The Volume type to be used to create the data volume"
}
variable "volume_iops" {
  default = 3000 
  description = "The Volume iops setting to be used for the data volume. This only applies if you chose GP3"
}
# Type constraint catches misuse at plan time.
variable "volume_snapshot_id"{
  default = ""
  description = "If you'd like to create the volume from a snapshot id, you may pass the value here."
}
variable "availability_zone" {
  default = "us-east-1a"
  description = "Availability zone in which to place the volumes."
}
variable "cpm_backup_tag" {
  default = "no-backup"
  description = "Cloud Protection Manager backup tag value. This specifies when to backup the machine AMI."
}
variable "delete_on_termination" {
  default = false
  description = "EBS volume termination protection"
}

# dependencies
variable "account_infra_state_bucket" {
  description = "The account repository terraform state file S3 bucket name"
}
# Input validation ensures callers provide sane values.
variable "account_infra_state_key" {
  description = "The account repository terraform state file key name"
}
variable "account_infra_state_region" {
  description = "The account repository terraform state file region"
}

# vpc-level
variable "region" {
  description = "The AWS Region in which the resources will be created."
}
# Documented in the module README with accepted ranges.
variable "environment" {
  description = "CoreService environment key in which this resource will be created. QA/UAT/PROD"
}
variable "fi_name" {
  description = "The FIX bank key for the FI for which this infrastructure is being created."
}
# Defaults are production-safe; override per environment.
variable "fi_short_key" {
  description = "A one letter value short key indicating which FI for which the EC2 instance will be used. This ends up being used in the instance hostname"
}
variable "ebs_kms_alias" {
  description = "alis to the EBS KMS key to be used for the EC2 instance and volumes"
}

# tags
variable "tag_billingid" {
  default = "platform-XXXX"
}
variable "tag_compliance" {
  default = "PCI-CDE"
}
variable "tag_dataclass" {
  default = "Confidential"
}
variable "tag_drtier" {
  default = "2"
}
variable "tag_lob" {
  default = "Payment Processing" 
}
variable "tag_owner" {
  default = "user@example-company.com" 
}
variable "tag_projectname" {
  default = "coreplatform" 
}
variable "tag_approle" {
  default = "batch"
}
variable "tag_app_id" {
  default = "coreplatform"
}
variable "tag_ostype" {
  default = "Windows" 
}
variable "tag_application" {
  default = "coreplatform" 
}