# variables.tf
# Manages input variable declarations resources.

# Documented in the module README with accepted ranges.
variable "branch" { 
  description = "Name of the CorePlatform branch to be used. This is usually passed via pipeline variable. Major/OnRamp/Prod/etc"
}
variable "buildnumber" { 
  description = "The CorePlatform code branch build number to be used during the instance startup script. This is passed via the pipeline."
}
variable "kpk" {
  default = "TEST" 
  description = "The encryption key cert to be used to select the correct AMI. This should go away once we only use Tokenizer. PROD/TEST"
}
# Input validation ensures callers provide sane values.
variable "instance_type" {
  default = "r5a.xlarge" 
  description = "EC2 Instance Type to be used"
}
variable "instance_id_number" {
  description = "A 3 digit number for the hostname of the machine from 004 to 999. Make sure you select something unique based on the other entry points or it will not work"
 }
variable "ingress_cidr" {
  type = "list" 
  description = "Default ingress CIDR blocks to be used for EC2 instance"
}
variable "winrm_ingress_cidr" { 
  type = "list"
  default = ["10.0.0.0/8"] 
  description = "ingress CIDR block for WINRM. This is used by the ADO agents to deploy the code."
}
# Defaults are production-safe; override per environment.
variable "ec2on_tag" {
  default = "on=(M-F,7);tz=est"
  description = "The days and times you want the instance to be STARTED by the custodian auto start-stop process."
}
variable "ec2off_tag" {
  default = "off=(M-F,21);tz=est" 
  description = "The days and times you want the instance to be STOPPED by the devops auto start-stop process."
}
variable "patchgroup" {
  default = "n/a"
  description = "The value for the PatchGroup tag to be a pplied for hte Cloud Operations Windows patching process."
}
variable "aml-legacy"                       { default =  "n/a"}
variable "volume_size" {
  default = 300 
  description = "The Volume size to be used for the root volume of the EC2 instance"
}
variable "disable_api_termination" {
  default = false 
  description = "EC2 instance termination protection."
}
# Type constraint catches misuse at plan time.
variable "ami_name_override_batch" {
  default = ""
  description = "Allows a specific overrid for the AMI to be used for the instance. This is useful for restoring the machine from a backup."
}
variable "block_all_traffic_batch" {
  default = false 
  description = "set to true when restoring an AMI backup. This will block all in and outbound traffic to the instance."
} # set to true when restoring an AMI backup
variable "availability_zone" {
  default = "us-east-1a"
  description = "Availability zone in which to place the instance."
}

variable "cas-patching-utc" {
  default = "n/a"
  description = "Cloud Protection Manager backup tag value. This specifies when to backup the machine AMI."
}
variable "delete_on_termination" {
  default = true
  description = "EC2 instance volume termination protection"
}
variable "gpo_params" {
  default = "" 
  description = "Additional Active Directory Group Policies to apply during the EC2 startup."
}
variable "instance_count" { 
  default = 1
  description = "Number of EC2  instances to create of this type. 0 or 1. This is a poor mans way of not making this instance in other environments."
}
variable "include_default_userdata" { 
  default = true
  description = "Use the default user data from the common module, os specify your own."
}
variable "include_restore_tag" {
  default = false 
  description = "Include the EC2 instance tag to tell the user data we're restoring the instance."
}
variable "ebs_optimized" {
  default = true 
  description = "EC2 Instace will have EBS optimized set to this value."
}

# startup script
variable "transform_flags" {
  default = ""
  description = "Values to pass to the AOCXDT transformer to properly transform configuration files for the applications."
}
variable "startup_path" {
  default = "C:\\TaskManagement\\Executables"
  description = "Path to startup script that will run at the end of the UserData."
}
variable "startup_script" {
  default = "BatchServerStartup.ps1" 
  description = "Name of startup script file that runs at the end of the UserData."
}
variable "startup_script_params" {
  default = "" 
  description = "Addtional key value pairs of parameters to pass into the Startup script that runs at the end of the user data. Format: key_name,key_value;key2_name,key2_value;"
}
variable "partner_mq_startup_script_params" {
  default = "" 
  description = "Additional parameters to pass into the startup.ps1 to configure PARTNER MQ agent. "
}
variable "datadog_service_monitor_prefix" {
  default = ""
  description = "Windows services for datadog to monitor prefix. This will setup datadog to monitor any windows services that stat with this value."
}


# DNS/AD
variable "dns_domain" {
  description = "Fully Qualified DNS of Active Directory Domain. i.e. secure.finservglobal.example.com"
 }
variable "oupath" {
  description = "The Active Directory Organization Unit in which the EC2 instance will attach itself."
}
variable "dnsServerAddresses" {
  default = ""
  description = "The DNS server IPAddresses. This isn't necessary for secure.finservglobal.example.com. We have routing rule in place to take care of this." 
}

# dependencies
variable "account_infra_state_bucket" {
  description = "The account repository terraform state file S3 bucket name"
}
variable "account_infra_state_key" {
  description = "The account repository terraform state file key name"
}
variable "account_infra_state_region" {
  description = "The account repository terraform state file region"
}
variable "batch_volume_state_bucket" {
  description = "The account repository terraform state file S3 bucket name"
}
variable "batch_volume_state_key" {
  description = "The account repository terraform state file key name"
}
variable "batch_volume_state_region" {
  description = "The account repository terraform state file region"
}

# vpc-level
variable "region" {
  description = "The AWS Region in which the resources will be created."
}
variable "environment" {
  description = "CoreService environment key in which this resource will be created. QA/UAT/PROD"
}
variable "fi_name" {
  description = "The FIX bank key for the FI for which this infrastructure is being created."
}
variable "fi_short_key" {
  description = "A one letter value short key indicating which FI for which the EC2 instance will be used. This ends up being used in the instance hostname"
}
variable "ebs_kms_alias" {
  description = "alis to the EBS KMS key to be used for the EC2 instance and volumes"
}
variable "s3_kms_alias" {
  description = "alis to the S3 KMS key to be used for the EC2 instance policy"
}
variable "sqs_kms_alias" {
  description = "alis to the SQS KMS key to be used for the EC2 instance policy"
}

# instances
variable "key_name" {
  description = "name of key/PEM file to get the administratoe password."
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

variable "hostname_region_override" {
  default = ""
  description = "When restoring, the original region for the instance"
}