# Variables
# ===============================================

# branch and buildnumber
variable "branch"                             { }
variable "buildnumber"                        { }
# Input validation ensures callers provide sane values.
variable "kpk"                                { }

# dependencies
variable "account_infra_state_bucket"         { }
variable "account_infra_state_key"            { }
# Required by upstream callers.
variable "account_infra_state_region"         { }

# vpc-level
variable "region"                             { }
variable "region_key"                         { }
variable "environment"                        { }
variable "fi_name"                            { }
variable "fi_name_public"                     { }
variable "fi_config"                          { }   # FI used in the UserData startup script for the config transforms, this will always be a real FI, e.g., corp or sample_fi
variable "fi_short_key"                       { } 
variable "ebs_kms_alias"                      { }
variable "s3_kms_alias"                       { }
variable "sqs_kms_alias"                      { }
variable "partition"                          { }
variable "account_id"                         { }

# instances
variable "key_name"                           { }
# Type constraint catches misuse at plan time.
variable "ebs_optimized"                      { default = true }
variable "transform_flags"                    { default = "" }

# shared
variable "sg_egress_cidr_block"               { type = "list" default = ["0.0.0.0/0"] }
# Documented in the module README with accepted ranges.
variable "lb_bucket_name"                     { default = ""}
variable "splunk_egress_cidr"                 { 
                                                type = "list"
                                                default = ["10.94.2.111/32"] 
                                              }
variable "gpo_params"                         { default = "ROLE-ENC-GPOSupplemental-IIS" }

# windows service server
variable "winservices_instance_type"          { default = "r5a.xlarge" }
variable "winservices_min_instances"          { default = 1 }
variable "winservices_max_instances"          { default = 1 }
variable "winservices_count"                  { default = 1 }
variable "winservices_volume_size"            { default = 100 }
# Defaults are production-safe; override per environment.
variable "winservices_ASGON_tag"              { default = "on=(M-F,7);tz=est" }
variable "winservices_ASGOFF_tag"             { default = "off=(M-F,21);tz=est" }
variable "winservices_default_cooldown"       { default = 300 }
variable "winservices_ingress_cidr"           { type = "list" default = ["10.0.0.0/8"] }
variable "winservices_asg_suspend_policy"     { type = "list", default = [] }

# log queue server
variable "logqserver_instance_type"           { default = "r5a.xlarge" }
variable "logqserver_min_instances"           { default = 1 }
variable "logqserver_max_instances"           { default = 1 }
variable "logqserver_volume_size"             { default = 100 }
variable "logqserver_ASGON_tag"               { default = "on=(M-F,7);tz=est" }
variable "logqserver_ASGOFF_tag"              { default = "off=(M-F,21);tz=est" }
variable "logqserver_default_cooldown"        { default = 300 }
variable "logqserver_ingress_cidr"            { type = "list" default = ["10.0.0.0/8"] }
variable "logqserver_asg_suspend_policy"      { type = "list", default = [] }
/*
>>> Future use
# job server
variable "jobserver_instance_type"            { default = "r5a.xlarge" }
variable "jobserver_volume_size"              { default = 100 }
variable "jobserver_ASGOFF_tag"               { default = "off=(M-F,21);tz=est" }
variable "jobserver_ASGON_tag"                { default = "on=(M-F,7);tz=est" }
variable "jobserver_default_cooldown"         { default = 300 }
variable "jobserver_ingress_cidr"             { type = "list" default = ["10.0.0.0/8"] }
variable "jobserver_ssh_port"                 { default = 22 }
variable "jobserver_ctm_em_port"              { default = 2370 }
variable "jobserver_ctm_process_port"         { default = 6005 }
variable "jobserver_ctm_agent_server"         { default = 7106 }
variable "jobserver_ctm_ha_port"              { default = 2368 }
variable "jobserver_ctm_em_agent_port"        { default = 2369 }
variable "jobserver_ctm_server_agent"         { default = 7105 }
variable "jobserver_startup_script_params"    { default = "" }
*/

# app server
variable "app_instance_type"                  { default = "c5a.large" }
variable "app_min_instances"                  { default = 2 }
variable "app_max_instances"                  { default = 2 }
variable "app_default_cooldown"               { default = 300 }
variable "app_volume_size"                    { default = 100 }
variable "app_ingress_cidr"                   { type = "list" default = ["10.0.0.0/8"] }
variable "app_egress_cidr"                    { type = "list" default = ["10.0.0.0/8"] }
variable "app_lb_internal"                    { default = true }
variable "app_lb_listener_port"               { default = 80 }
variable "app_lb_listener_proto"              { default = "HTTP" }
variable "app_lb_certificate_arn"             { default = "" }
variable "app_lb_ssl_policy"                  { default = "" }
variable "app_lb_access_logging"              { default = false }
variable "app_lb_idle_timeout"                { default = 600 }
variable "app_ASGOFF_tag"                     { default = "off=(M-F,21);tz=est" }
variable "app_ASGON_tag"                      { default = "on=(M-F,7);tz=est" }
variable "app_site_id"                        { default = "10" }
variable "app_asg_suspend_policy"             { type = "list", default = [] }

# www server
variable "www_instance_type"                  { default = "r5a.large" }
variable "www_min_instances"                  { default = 2 }
variable "www_max_instances"                  { default = 2 }
variable "www_default_cooldown"               { default = 300 }
variable "www_volume_size"                    { default = 100 }
variable "www_ingress_cidr"                   { type = "list" default = ["10.0.0.0/8"] }
variable "www_lb_internal"                    { default = true }
variable "www_lb_listener_port"               { default = 80 }
variable "www_lb_listener_proto"              { default = "HTTP" }
variable "www_lb_certificate_arn"             { default = "" }
variable "www_lb_ssl_policy"                  { default = "" }
variable "www_lb_access_logging"              { default = true }
variable "www_lb_idle_timeout"                { default = 600 }
variable "www_ASGOFF_tag"                     { default = "off=(M-F,21);tz=est" }
variable "www_ASGON_tag"                      { default = "on=(M-F,7);tz=est" }
variable "www_site_id"                        { default = "20" }
variable "www_asg_suspend_policy"             { type = "list", default = [] }

# svc server
variable "svc_instance_type"                  { default = "r5a.large" }
variable "svc_min_instances"                  { default = 2 }
variable "svc_max_instances"                  { default = 2 }
variable "svc_default_cooldown"               { default = 300 }
variable "svc_volume_size"                    { default = 100 }
variable "svc_ingress_cidr"                   { type = "list" default = ["10.0.0.0/8"] }
variable "svc_lb_internal"                    { default = true }
variable "svc_lb_listener_port"               { default = 80 }
variable "svc_lb_listener_proto"              { default = "HTTP" }
variable "svc_lb_certificate_arn"             { default = "" }
variable "svc_lb_ssl_policy"                  { default = "" }
variable "svc_lb_access_logging"              { default = true }
variable "svc_lb_idle_timeout"                { default = 600 }
variable "svc_ASGOFF_tag"                     { default = "off=(M-F,21);tz=est" }
variable "svc_ASGON_tag"                      { default = "on=(M-F,7);tz=est" }
variable "svc_site_id"                        { default = "30" }
variable "svc_asg_suspend_policy"             { type = "list", default = [] }
# Boolean to create R53 record in private hosted zone
variable "create_r53_private"                 { default = true }
# Boolean to create R53 record in public hosted zone
variable "create_r53_public"                  { default = false }
# Imperva CNAME for public corp svc record
variable "finserv_svc_imperva_cname"              { default = "" }

# taskmanapp server
variable "taskmanapp_instance_type"            { default = "r5a.large" }
variable "taskmanapp_min_instances"            { default = 2 }
variable "taskmanapp_max_instances"            { default = 2 }
variable "taskmanapp_default_cooldown"         { default = 300 }
variable "taskmanapp_volume_size"              { default = 100 }
variable "taskmanapp_ingress_cidr"             { type = "list" default = ["10.0.0.0/8"] }
variable "taskmanapp_lb_internal"              { default = true }
variable "taskmanapp_lb_listener_port"         { default = 80 }
variable "taskmanapp_lb_listener_proto"        { default = "HTTP" }
variable "taskmanapp_lb_certificate_arn"       { default = "" }
variable "taskmanapp_lb_ssl_policy"            { default = "" }
variable "taskmanapp_lb_access_logging"        { default = false }
variable "taskmanapp_ASGOFF_tag"               { default = "off=(M-F,21);tz=est" }
variable "taskmanapp_ASGON_tag"                { default = "on=(M-F,7);tz=est" }
variable "taskmanapp_site_id"                  { default = "10" }
variable "taskmanapp_asg_suspend_policy"       { type = "list", default = [] }

# taskmanweb server
variable "taskmanweb_instance_type"            { default = "r5a.large" }
variable "taskmanweb_min_instances"            { default = 2 }
variable "taskmanweb_max_instances"            { default = 2 }
variable "taskmanweb_default_cooldown"         { default = 300 }
variable "taskmanweb_volume_size"              { default = 100 }
variable "taskmanweb_ingress_cidr"             { type = "list" default = ["10.0.0.0/8"] }
variable "taskmanweb_lb_internal"              { default = true }
variable "taskmanweb_lb_listener_port"         { default = 80 }
variable "taskmanweb_lb_listener_proto"        { default = "HTTP" }
variable "taskmanweb_lb_certificate_arn"       { default = "" }
variable "taskmanweb_lb_ssl_policy"            { default = "" }
variable "taskmanweb_lb_access_logging"        { default = false }
variable "taskmanweb_ASGOFF_tag"               { default = "off=(M-F,21);tz=est" }
variable "taskmanweb_ASGON_tag"                { default = "on=(M-F,7);tz=est" }
variable "taskmanweb_site_id"                  { default = "10" }
variable "taskmanweb_asg_suspend_policy"       { type = "list", default = [] }
variable "taskmanweb_lb_ingress_port"          { default = 443 }

variable "cerberus_sg_api_listener_port"      { default = 10001 }

#variable "custext_instance_type"             { default = "r5a.large" }
#variable "custext_rdp_allow"                 { type = "list" default = ["10.0.0.0/8"] }
#variable "custext_EC2OFF_tag"                { default = "off=(M-F,21);tz=est" }

# winrm
variable "winrm_ingress_cidr"                 { type = "list" default = ["10.0.0.0/8"] }

# web application firewall CIDRs
variable "waf_ingress_cidr"                   { type = "list" default = ["10.0.0.0/8"] }
variable "qualys_public_ingress_cidr"         { type = "list" default = ["10.0.0.0/8"] }

# build servers need access to db server
variable "buildserver_ingress_cidr"           { type = "list" }


# tags
variable "tag_billingid"                      { default = "platform-XXXX" }
variable "tag_compliance"                     { default = "PCI-CDE" }
variable "tag_dataclass"                      { default = "Confidential" }
variable "tag_drtier"                         { default = "1" }
variable "tag_lob"                            { default = "Payment Processing" }
variable "tag_owner"                          { default = "user@example-company.com" }
variable "tag_projectname"                    { default = "coreplatform" }
variable "tag_approle"                        { default = "app" }
variable "tag_app_id"                         { default = "APP_44819" } # I looked this up in cherwell
variable "tag_ostype"                         { default = "Windows" }
variable "tag_application"                    { default = "coreplatform" }

# redis - session db
variable "redis_elasticache_node_type"                 { default = "cache.r5.large" }
variable "redis_elasticache_replicas_per_node_group"   { default = 1 }
variable "redis_elasticache_num_node_groups"           { default = 2 }
variable "redis_elasticache_engine_version"            { default = "" }
variable "redis_parameter_group_name"                  { default = "default.redis6.x.cluster.on" } # cluster mode enabled

# redis - invoice parser batch db
variable "redis_invoiceparser_node_type"               { default = "cache.r5.large" }
variable "redis_invoiceparser_replicas_per_node_group" { default = 1 }
variable "redis_invoiceparser_num_node_groups"         { default = 2 }
variable "redis_invoiceparser_engine_version"          { default = "" }
variable "redis_invoiceparser_parameter_group_name"    { default = "default.redis6.x" } # cluster mode disabled

# DNS/AD
variable "dns_domain"                                  { }
variable "tier1_oupath"                                { }
variable "tier2_oupath"                                { }
variable "dnsServerAddresses"                          { default = "" }

# sns topic
variable "sns_unhealthy_instance_topic"                { default = "CorePlatform-LoadBalancer-UnhealthyInstances" }

# PARTNER MQ config values used by MQ Client
variable "partner_mq_startup_script_params"                { default = "" }

# Datadog services to monitor
variable "datadog_service_monitor_prefix"              { default = "" }
#Datadog Monitoring default except in prod, proddr and uat
variable "datadog_enable"                              { default = "true" }
# Security group id for yeti-mod ecs services
variable "ecs_yeti_mod_sg"                             { default = "" }

# Security group id for dsc-mod ecs services
variable "ecs_dsc_mod_sg"                              { default = "" }

# Security group id for prefund-reporting-mod ecs services
variable "ecs_prefund_reporting_mod_sg"                { default = "" }

#cpm backup tag for the cattles
variable "cpm_backup_tag"                              { default = "no-backup" }

variable "unhealthy_alarm_arn"                         { default = "" }

# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"     = "UE1"
    "us-west-2"     = "UW2"
  }

  env_keys = {
    "dev"           = "D"
    "uat"           = "U"
    "stage"         = "S"
    "demo"          = "C"
    "prod"          = "P"
    "qa"            = "Q"
  }

  short_region_keys = {
    "us-east-1"     = "E"
    "us-west-2"     = "W"
  }

  region_dns_suffix = "${lower(var.region) == "us-east-1" ? "" : "-${lower(lookup(local.region_keys, var.region))}"}"
}


# Datasources
# =================================================

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}

data "aws_vpc" "vpc" {
  id = "${data.terraform_remote_state.account_infrastructure.vpc_id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Public"
  }
}

data "aws_kms_alias" "ebs_key" {
  name = "${var.ebs_kms_alias}"
}

data "aws_kms_alias" "s3_key" {
  name = "${var.s3_kms_alias}"
}

data "aws_kms_alias" "sqs_key" {
  name = "${var.sqs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Shared security group for multiple servers (twilio/efax)
# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "twilio_efax_sg" {
  count = 1 
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-twilioefax-custom-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  egress = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_egress_cidr_block}"]
  },
   {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_egress_cidr_block}"]
  }
  ]
}

# Module Calls
# =================================================

# -- Common Tags --
# Module sourced from internal registry — pin version to prevent unexpected changes
module "cpt_tags" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//cpt_tags"

  billingid   = "${var.tag_billingid}"
  compliance  = "${var.tag_compliance}"
  dataclass   = "${var.tag_dataclass}"
  drtier      = "${var.tag_drtier}"
  environment = "${var.environment}"
  finame      = "${var.fi_name}"  
  lob         = "${var.tag_lob}"
  owner       = "${var.tag_owner}"
  projectname = "${var.tag_projectname}"
  approle     = "${var.tag_approle}"
  app_id      = "${var.tag_app_id}"
  ostype      = "${var.tag_ostype}"
  application = "${var.tag_application}"
}

# -- Winservices --
data "aws_ami" "winservices_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-WinService-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "winsvc_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:DeleteObjectVersion",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow",
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow/*",
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*",
    ]
  }
  
  statement {
    sid = "kms1"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
    ]

    resources = [
		  "${data.aws_kms_alias.s3_key.arn}",
      "${data.aws_kms_alias.s3_key.target_key_arn}",
      "${data.aws_kms_alias.sqs_key.arn}",
      "${data.aws_kms_alias.sqs_key.target_key_arn}",
    ]
  },

  statement {
    sid = "kms2"

    actions = [
      "kms:ListKeys",
      "kms:ListAliases"
    ]

    resources = ["*"]
  },

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/adpassword*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
      # TODO: when we have a secrets naming convention update this to be FI and Env specific
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:EMAILBOUNCE*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SendGridSMTPCredentials/${lower(var.environment)}/${lower(var.fi_name)}*",
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-*",
      "arn:${data.aws_partition.current.partition}:sqs:us-east-1:111111111107:coreplatform_p-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-east-1:111111111107:coreplatform_m-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-west-2:111111111107:coreplatform_p-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-west-2:111111111107:coreplatform_m-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-east-1:111111111108:coreplatform_p-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-east-1:111111111108:coreplatform_m-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-west-2:111111111108:coreplatform_p-log-create_*",
      "arn:${data.aws_partition.current.partition}:sqs:us-west-2:111111111108:coreplatform_m-log-create_*",
    ]
  }
}

# -- Unhealthy Instance Topic --
# Shared module — changes here affect all consumers. Semver applies.
module "unhealthy_instance_topic" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sns_topic"
  
   name                       = "${upper(var.fi_name)}-${var.sns_unhealthy_instance_topic}"
   sns_key_id                 = "alias/coreplatform-${var.environment}-${lower(lookup(local.region_keys, var.region))}-sns-kms-key"
}


module "winservices_asg" { 
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-winsvc"
  fi_name                    = "${var.fi_config}"
  environment                = "${var.environment}"
  hostname                   = "A${lookup(local.region_keys, var.region)}WINSVC${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  key_name                   = "${var.key_name}"
  image_id                   = "${data.aws_ami.winservices_ami.id}"
  instance_type              = "${var.winservices_instance_type}"
  ebs_optimized              = "${var.ebs_optimized}"
  volume_size                = "${var.winservices_volume_size}"
  min_size                   = "${var.winservices_min_instances}"
  max_size                   = "${var.winservices_max_instances}"
  default_cooldown           = "${var.winservices_default_cooldown}"
  ingress_cidr               = "${var.winservices_ingress_cidr}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  ASGON_tag                  = "${var.winservices_ASGON_tag}"
  ASGOFF_tag                 = "${var.winservices_ASGOFF_tag}"
  tags                       = "${merge(module.cpt_tags.tags,map("drtier","2"))}"
  asg_tags                   = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json   = "${data.aws_iam_policy_document.winsvc_policy_document.json}"
  startup_path               = "C:\\CorePlatform\\WinServices"
  startup_script             = "startup.ps1"
  startup_script_params      = "branch,${var.branch};${var.partner_mq_startup_script_params};${var.datadog_service_monitor_prefix}"
  site_id                    = ""
  health_check_grace_period  = "1200"
  health_check_type          = "EC2"
  datadog_enable             = "${var.datadog_enable}"
  ad_password_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.tier2_oupath}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  suspended_processes        = ["${var.winservices_asg_suspend_policy}"]
  lb_sgs                     = [] # no LB for this instance
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_third_party_services_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_partner_mq_sg_id}"
  ]
  uselifecyclehook           = "true"
  transform_flags            = "${var.transform_flags}"
}

module "logqserver_asg" { 
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-logqserver"
  fi_name                    = "${var.fi_config}"
  environment                = "${var.environment}"
  hostname                   = "A${lookup(local.region_keys, var.region)}LGQSVR${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  key_name                   = "${var.key_name}"
  image_id                   = "${data.aws_ami.winservices_ami.id}"
  instance_type              = "${var.logqserver_instance_type}"
  ebs_optimized              = "${var.ebs_optimized}"
  volume_size                = "${var.logqserver_volume_size}"
  min_size                   = "${var.logqserver_min_instances}"
  max_size                   = "${var.logqserver_max_instances}"
  default_cooldown           = "${var.logqserver_default_cooldown}"
  ingress_cidr               = "${var.logqserver_ingress_cidr}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  ASGON_tag                  = "${var.logqserver_ASGON_tag}"
  ASGOFF_tag                 = "${var.logqserver_ASGOFF_tag}"
  tags                       = "${merge(module.cpt_tags.tags,map("drtier","2"))}"
  asg_tags                   = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json   = "${data.aws_iam_policy_document.winsvc_policy_document.json}"
  startup_path               = "C:\\CorePlatform\\WinServices"
  startup_script             = "Startup-Logqserver.ps1"
  startup_script_params      = "branch,${var.branch};${var.partner_mq_startup_script_params};${var.datadog_service_monitor_prefix}"
  site_id                    = ""
  health_check_type          = "EC2"
  health_check_grace_period  = "1200"
  datadog_enable             = "${var.datadog_enable}"
  ad_password_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.tier2_oupath}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  suspended_processes        = ["${var.logqserver_asg_suspend_policy}"]
  lb_sgs                     = [] # no LB for this instance
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_partner_mq_sg_id}"]
  uselifecyclehook           = "true"
  transform_flags            = "${var.transform_flags}"
}

/*
>>> Future use
# -- JobServer --
data "aws_ami" "jobserver_ami" {
  most_recent = true
  owners      = ["111111111114"]
                  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-JobServer-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "jobserver_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow",
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow/*",
    ]
  }

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/adpassword*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:controlM/${var.environment}/API*",
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-*",
    ]
  }

  statement {
    sid = "dynamodb"

    actions = [
      "dynamodb:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-jobdb",
    ]
  }
}

# Additional security rule for CM primary/secondary servers so job server can ping
resource "aws_security_group" "jobserver_custom_sg" {
  count = 1
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-jobsvr-custom-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ssh_port}"
      to_port     = "${var.jobserver_ssh_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_ha_port}"
      to_port     = "${var.jobserver_ctm_ha_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_em_agent_port}"
      to_port     = "${var.jobserver_ctm_em_agent_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_em_port}"
      to_port     = "${var.jobserver_ctm_em_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_process_port}"
      to_port     = "${var.jobserver_ctm_process_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_server_agent}"
      to_port     = "${var.jobserver_ctm_server_agent}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }, 
    {
      from_port   = "${var.jobserver_ctm_agent_server}"
      to_port     = "${var.jobserver_ctm_agent_server}"
      protocol    = "tcp"
      cidr_blocks = ["${var.jobserver_ingress_cidr}"]
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "jobserver_asg" { 
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                      = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-jobsvr"
  fi_name                   = "${var.fi_config}"
  environment               = "${var.environment}"
  hostname                  = "A${lookup(local.region_keys, var.region)}JOBSVR${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                    = "${data.aws_vpc.vpc.id}"
  key_name                  = "${var.key_name}"
  image_id                  = "${data.aws_ami.jobserver_ami.id}"
  instance_type             = "${var.jobserver_instance_type}"
  ebs_optimized             = "${var.ebs_optimized}"
  volume_size               = "${var.jobserver_volume_size}"
  min_size                  = "1"
  max_size                  = "1"
  default_cooldown          = "${var.jobserver_default_cooldown}"
  ingress_cidr              = "${var.jobserver_ingress_cidr}"
  subnet_ids                = ["${data.aws_subnet_ids.private.ids}"]
  ASGON_tag                 = "${var.jobserver_ASGON_tag}"
  ASGOFF_tag                = "${var.jobserver_ASGOFF_tag}"
  tags                      = "${module.cpt_tags.tags}"
  tags                       = "${merge(module.cpt_tags.tags, map("drtier", "2"))}"
  asg_tags                  = ["${module.cpt_tags.autoscaling_tags}"]
  ebs_kms_key_id            = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json  = "${data.aws_iam_policy_document.jobserver_policy_document.json}"
  startup_path              = "C:\\TaskManagement\\Executables"
  startup_script            = "startup.ps1"
  startup_script_params     = "${var.jobserver_startup_script_params}"
  site_id                   = ""
  health_check_grace_period = "1200"
  health_check_type         = "EC2"
  datadog_enable            = "${var.datadog_enable}"
  ad_password_secrets_arn   = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn   = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                = "${var.dns_domain}"
  oupath                    = "${var.tier2_oupath}"
  dnsServerAddresses        = "${var.dnsServerAddresses}"
  additional_security_groups=["${aws_security_group.jobserver_custom_sg.id}"]
  uselifecyclehook          = "true"
  transform_flags            = "${var.transform_flags}"
}
*/


# -- App server ASG --
data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "app_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow",
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow/*",
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*",
    ]
  }

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SendGridSMTPCredentials/${lower(var.environment)}/${lower(var.fi_name)}*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ApiKeys/${upper(var.environment)}/*",
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.region_key}-cpt-enc-${var.fi_name}-${var.environment}-sqs-*",
    ]
  },

  statement {
    sid = "kms1"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
    ]

    resources = [
      "${data.aws_kms_alias.sqs_key.arn}",
      "${data.aws_kms_alias.sqs_key.target_key_arn}",
    ]
  },

  statement {
    sid = "kms2"

    actions = [
      "kms:ListKeys",
      "kms:ListAliases"
    ]

    resources = ["*"]
  }
}  

module "app_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "2"))}"
  lb_internal                     = "${var.app_lb_internal}"
  lb_listener_port                = "${var.app_lb_listener_port}"
  lb_listener_proto               = "${var.app_lb_listener_proto}"
  lb_certificate_arn              = "${var.app_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.app_lb_ssl_policy}"
  lb_access_logging               = "${var.app_lb_access_logging}"
  bucket_name                     = "${var.lb_bucket_name}"
  lb_ingress_cidr                 = "${var.app_ingress_cidr}"
  lb_idle_timeout                 = "${var.app_lb_idle_timeout}"
  target_protocol                 = "HTTP"
  target_group_port               = 80
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 3
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule     = false # override inbound sg rules below
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

# Override app LB security group rules
resource "aws_security_group_rule" "app_server_lb_inbound_www" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from www server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.www_server_asg.cluster_sg_id}"
}

# Override app dbtools security group rules
resource "aws_security_group_rule" "app_server_dbtools_sg_rule" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from dbtools server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${data.aws_security_group.dbtools_security_group.id}"
}


resource "aws_security_group_rule" "app_server_lb_inbound_svc" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from svc server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.svc_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "app_server_lb_inbound_logqueue" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from log queue server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.logqserver_asg.cluster_sg_id}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "app_server_lb_inbound_winservices" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from Windows service server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.winservices_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "app_server_lb_inbound_ecs_yeti_mod" {
  count                    =  "${(var.ecs_yeti_mod_sg != "")? 1 : 0}" # Create when ecs_yeti_mod_sg is not empty

  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from yeti mod ecs services"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_yeti_mod_sg }"
}

resource "aws_security_group_rule" "app_server_lb_inbound_ecs_dsc_mod" {
  count                    =  "${(var.ecs_dsc_mod_sg != "")? 1 : 0}" # Create when ecs_dsc_mod_sg is not empty

  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from dsc mod ecs services"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_dsc_mod_sg }"
}

resource "aws_security_group_rule" "app_server_lb_inbound_ecs_prefund_reporting_mod" {
  count                    =  "${(var.ecs_prefund_reporting_mod_sg != "")? 1 : 0}" # Create when ecs_prefund_reporting_mod_sg is not empty

  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Inbound from prefund-reporting mod ecs services"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_prefund_reporting_mod_sg }"
}

resource "aws_security_group_rule" "app_server_lb_outbound_app" {
  security_group_id        = "${module.app_server_lb.lb_sg_id}"
  description              = "Outbound to app server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.app_server_asg.cluster_sg_id}"
}

module "app_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app"
  fi_name                         = "${var.fi_config}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}APPSVR${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.app_ami.id}"
  instance_type                   = "${var.app_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.app_volume_size}"
  min_size                        = "${var.app_min_instances}"
  max_size                        = "${var.app_max_instances}"
  default_cooldown                = "${var.app_default_cooldown}"
  ingress_cidr                    = "${var.app_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.app_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.app_ASGON_tag}"
  ASGOFF_tag                      = "${var.app_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","2"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.app_policy_document.json}"
  startup_path                    = "C:\\CoreService\\APP"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch};${var.partner_mq_startup_script_params}"
  site_id                         = "${var.app_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  datadog_enable                  = "${var.datadog_enable}"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier2_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.app_asg_suspend_policy}"]
  lb_sgs                          = ["${module.app_server_lb.lb_sg_id}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}", 
    "${data.terraform_remote_state.account_infrastructure.outbound_partner_mq_sg_id}", 
    "${data.terraform_remote_state.account_infrastructure.jobs_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_sftp_sg_id}" 
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

data "aws_lb" "app_lb" {
  arn  = "${module.app_server_lb.lb_id}"
}

resource "aws_route53_record" "app_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-app"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.app_lb.dns_name}"
    zone_id                = "${data.aws_lb.app_lb.zone_id}"
    evaluate_target_health = true
  }
}


# -- WWW server ASG --
data "aws_ami" "www_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "www_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*"
    ]
  }

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
  	  "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/Web*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*"
    ]
  }
}

module "www_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                                      = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-www"
  vpc_id                                    = "${data.aws_vpc.vpc.id}"
  #subnet_ids                               = ["${var.www_lb_internal ? "${data.aws_subnet_ids.private.ids}" : "${data.aws_subnet_ids.public.ids}"}"]
  #subnet_ids                               = [ "${split(",", var.www_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", list(data.aws_subnet_ids.public.ids, "")))}" ]
  subnet_ids                                = [ "${split(",", var.www_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", data.aws_subnet_ids.public.ids))}" ]
  tags                                      = "${merge(module.cpt_tags.tags, map("drtier", "1"))}"
  lb_internal                               = "${var.www_lb_internal}"
  lb_listener_port                          = "${var.www_lb_listener_port}"
  lb_listener_proto                         = "${var.www_lb_listener_proto}"
  lb_certificate_arn                        = "${var.www_lb_certificate_arn}"
  lb_ssl_policy                             = "${var.www_lb_ssl_policy}"
  lb_access_logging                         = "${var.www_lb_access_logging}"
  bucket_name                               = "${var.lb_bucket_name}"
  lb_ingress_cidr                           = "${var.www_ingress_cidr}"
  lb_idle_timeout                           = "${var.www_lb_idle_timeout}"
  target_protocol                           = "HTTP"
  target_group_port                         = 80
  healthcheck_enabled                       = true
  healthcheck_interval                      = 90
  healthcheck_path                          = "/css.htm"
  healthcheck_port                          = "traffic-port"
  healthcheck_protocol                      = "HTTP"
  healthcheck_timeout                       = 30
  healthcheck_healthy_threshold             = 3
  healthcheck_unhealthy_threshold           = 10
  healthcheck_matcher                       = "200"
  use_secondary_target                      = true
  secondary_target_protocol                 = "HTTP"
  secondary_target_group_port               = 81
  secondary_healthcheck_enabled             = true
  secondary_healthcheck_interval            = 90
  secondary_healthcheck_path                = "/css.htm"
  secondary_healthcheck_port                = "traffic-port"
  secondary_healthcheck_protocol            = "HTTP"
  secondary_healthcheck_timeout             = 30
  secondary_healthcheck_healthy_threshold   = 3
  secondary_healthcheck_unhealthy_threshold = 10
  secondary_healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn             = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule               = false # override inbound sg rules below
  use_default_egress_sg_rule                = false # override outbound sg rules below
}

resource "aws_security_group_rule" "www_server_lb_outbound_www" {
  security_group_id        = "${module.www_server_lb.lb_sg_id}"
  description              = "Outbound to www server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 81
  protocol                 = "tcp"
  source_security_group_id = "${module.www_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "www_server_lb_inbound_waf" {
  security_group_id        = "${module.www_server_lb.lb_sg_id}"
  description              = "Inbound from WAF"
  type                     = "ingress"
  from_port                = "${var.www_lb_listener_port}"
  to_port                  = "${var.www_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.waf_ingress_cidr}"]
}

 resource "aws_security_group_rule" "www_server_lb_inbound_qualys" {
  security_group_id        = "${module.www_server_lb.lb_sg_id}"
  description              = "Inbound from Qualys"
  type                     = "ingress"
  from_port                = "${var.www_lb_listener_port}"
  to_port                  = "${var.www_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.qualys_public_ingress_cidr}"]
}

module "www_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-www"
  fi_name                         = "${var.fi_config}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}WWWSVR${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.www_ami.id}"
  instance_type                   = "${var.www_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.www_volume_size}"
  min_size                        = "${var.www_min_instances}"
  max_size                        = "${var.www_max_instances}"
  default_cooldown                = "${var.www_default_cooldown}"
  ingress_cidr                    = "${var.www_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.www_server_lb.lb_tg_arn}", "${module.www_server_lb.lb_secondary_tg_arn}"]
  ASGON_tag                       = "${var.www_ASGON_tag}"
  ASGOFF_tag                      = "${var.www_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","1"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.www_policy_document.json}"
  startup_path                    = "C:\\CoreService\\WWW"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch}"
  site_id                         = "${var.www_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  datadog_enable                  = "${var.datadog_enable}"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier1_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.www_asg_suspend_policy}"]
  lb_sgs                          = ["${module.www_server_lb.lb_sg_id}"]
  lb_to_port                      = 81
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

# -- Svc server ASG --
data "aws_ami" "svc_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "svc_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*"
    ]
  }
  
  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
  	  "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/Web*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*"
    ]
  }
}

module "svc_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-svc"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  #subnet_ids                     = ["${data.aws_subnet_ids.private.ids}"]                concat(data.aws_vpcs.found.ids, list(""))
  subnet_ids                      = [ "${split(",", var.svc_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", concat(data.aws_subnet_ids.public.ids, list(""))))}" ]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1"))}"
  lb_internal                     = "${var.svc_lb_internal}"
  lb_listener_port                = "${var.svc_lb_listener_port}"
  lb_listener_proto               = "${var.svc_lb_listener_proto}"
  lb_certificate_arn              = "${var.svc_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.svc_lb_ssl_policy}"
  lb_ingress_cidr                 = "${var.svc_ingress_cidr}"
  lb_idle_timeout                 = "${var.svc_lb_idle_timeout}"
  target_protocol                 = "HTTP"
  target_group_port               = 80
  healthcheck_enabled             = true
  lb_access_logging               = "${var.svc_lb_access_logging}"
  bucket_name                     = "${var.lb_bucket_name}"
  healthcheck_interval            = 30
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 3
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule     = false
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

resource "aws_security_group_rule" "svc_server_lb_outbound_svc" {
  security_group_id        = "${module.svc_server_lb.lb_sg_id}"
  description              = "Outbound to svc server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.svc_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "svc_server_lb_inbound_vpc" {
  security_group_id        = "${module.svc_server_lb.lb_sg_id}"
  description              = "Inbound from internal VPC"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}
resource "aws_security_group_rule" "svc_server_lb_inbound_waf" {
  security_group_id        = "${module.svc_server_lb.lb_sg_id}"
  description              = "Inbound from WAF"
  type                     = "ingress"
  from_port                = "${var.svc_lb_listener_port}"
  to_port                  = "${var.svc_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.waf_ingress_cidr}"]
}
resource "aws_security_group_rule" "svc_server_lb_inbound_qualys" {
  security_group_id        = "${module.svc_server_lb.lb_sg_id}"
  description              = "Inbound from Qualys"
  type                     = "ingress"
  from_port                = "${var.svc_lb_listener_port}"
  to_port                  = "${var.svc_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.qualys_public_ingress_cidr}"]
}

module "svc_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-svc"
  fi_name                         = "${var.fi_config}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}SVCSVR${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.svc_ami.id}"
  instance_type                   = "${var.svc_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.svc_volume_size}"
  min_size                        = "${var.svc_min_instances}"
  max_size                        = "${var.svc_max_instances}"
  default_cooldown                = "${var.svc_default_cooldown}"
  ingress_cidr                    = "${var.svc_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.svc_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.svc_ASGON_tag}"
  ASGOFF_tag                      = "${var.svc_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","1"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.svc_policy_document.json}"
  startup_path                    = "C:\\CoreService\\SVC"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch}"
  site_id                         = "${var.svc_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  datadog_enable                  = "${var.datadog_enable}"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier1_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.svc_asg_suspend_policy}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  lb_sgs                          = ["${module.svc_server_lb.lb_sg_id}"]
  uselifecyclehook                = "true" 
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

# TaskMan App and Web

# -- TaskManWeb server ASG --
data "aws_ami" "taskmanweb_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "taskmanweb_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*"
    ]
  }

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
  	  "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/Web*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*"
    ]
  }
}

module "taskmanweb_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-jobweb"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = [ "${split(",", var.taskmanweb_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", concat(data.aws_subnet_ids.public.ids, list(""))))}" ]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1"))}"
  lb_internal                     = "${var.taskmanweb_lb_internal}"
  lb_listener_port                = "${var.taskmanweb_lb_listener_port}"
  lb_listener_proto               = "${var.taskmanweb_lb_listener_proto}"
  lb_certificate_arn              = "${var.taskmanweb_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.taskmanweb_lb_ssl_policy}"
  lb_ingress_cidr                 = "${var.taskmanweb_ingress_cidr}"
  target_protocol                 = "HTTP"
  target_group_port               = 80
  healthcheck_enabled             = true
  lb_access_logging               = "${var.taskmanweb_lb_access_logging}"
  bucket_name                     = "${var.lb_bucket_name}"
  healthcheck_interval            = 90
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 30
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 10
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule     = false # override inbound sg rules below
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

resource "aws_security_group_rule" "jmweb_server_lb_outbound_jmweb" {
  security_group_id        = "${module.taskmanweb_server_lb.lb_sg_id}"
  description              = "Outbound to TaskMan web server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.taskmanweb_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "jmweb_server_lb_inbound_waf" {
  security_group_id        = "${module.taskmanweb_server_lb.lb_sg_id}"
  description              = "Inbound from WAF"
  type                     = "ingress"
  from_port                = "${var.taskmanweb_lb_ingress_port}"
  to_port                  = "${var.taskmanweb_lb_ingress_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.waf_ingress_cidr}"]
}

resource "aws_security_group_rule" "jmweb_server_lb_inbound_qualys" {
  security_group_id        = "${module.taskmanweb_server_lb.lb_sg_id}"
  description              = "Inbound from Qualys"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["${var.qualys_public_ingress_cidr}"]
}

module "taskmanweb_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-taskmanweb"
  fi_name                         = "${var.fi_config}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}JOBWEB${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.taskmanweb_ami.id}"
  instance_type                   = "${var.taskmanweb_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.taskmanweb_volume_size}"
  min_size                        = "${var.taskmanweb_min_instances}"
  max_size                        = "${var.taskmanweb_max_instances}"
  default_cooldown                = "${var.taskmanweb_default_cooldown}"
  ingress_cidr                    = "${var.taskmanweb_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.taskmanweb_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.taskmanweb_ASGON_tag}"
  ASGOFF_tag                      = "${var.taskmanweb_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","1"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.taskmanweb_policy_document.json}"
  startup_path                    = "C:\\TaskManagement\\TaskManWeb"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch}"
  site_id                         = "${var.taskmanweb_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  datadog_enable                  = "${var.datadog_enable}"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier1_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.taskmanweb_asg_suspend_policy}"]
  lb_sgs                          = ["${module.taskmanweb_server_lb.lb_sg_id}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

# -- TaskManApp server ASG --
data "aws_ami" "taskmanapp_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "taskmanapp_policy_document" {

  statement {
    sid = "s3"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow",
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow/*",
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*",
    ]
  }

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-ALLFIS-SmsAuthToken*",
    ]
  }

}

module "taskmanapp_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-jobapp"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "2"))}"
  lb_internal                     = "${var.taskmanapp_lb_internal}"
  lb_access_logging               = "${var.taskmanapp_lb_access_logging}"
  bucket_name                     = "${var.lb_bucket_name}"
  lb_listener_port                = "${var.taskmanapp_lb_listener_port}"
  lb_listener_proto               = "${var.taskmanapp_lb_listener_proto}"
  lb_certificate_arn              = "${var.taskmanapp_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.taskmanapp_lb_ssl_policy}"
  lb_ingress_cidr                 = "${var.taskmanapp_ingress_cidr}"
  target_protocol                 = "HTTP"
  target_group_port               = 80
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 3
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule     = false # override inbound sg rules below
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

# Override app LB security group rules
resource "aws_security_group_rule" "jmapp_server_lb_inbound_jmweb" {
  security_group_id        = "${module.taskmanapp_server_lb.lb_sg_id}"
  description              = "Inbound from TaskMan web server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.taskmanweb_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "jmapp_server_lb_outbound_jmapp" {
  security_group_id        = "${module.taskmanapp_server_lb.lb_sg_id}"
  description              = "Outbound to TaskMan app server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.taskmanapp_server_asg.cluster_sg_id}"
}

module "taskmanapp_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-taskmanapp"
  fi_name                         = "${var.fi_config}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}JOBAPP${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.taskmanapp_ami.id}"
  instance_type                   = "${var.taskmanapp_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.taskmanapp_volume_size}"
  min_size                        = "${var.taskmanapp_min_instances}"
  max_size                        = "${var.taskmanapp_max_instances}"
  default_cooldown                = "${var.taskmanapp_default_cooldown}"
  ingress_cidr                    = "${var.taskmanapp_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.taskmanapp_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.taskmanapp_ASGON_tag}"
  ASGOFF_tag                      = "${var.taskmanapp_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","2"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.taskmanapp_policy_document.json}"
  startup_path                    = "C:\\TaskManagement\\TaskManApp"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch};${var.partner_mq_startup_script_params}"
  site_id                         = "${var.taskmanapp_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  datadog_enable                  = "${var.datadog_enable}"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier2_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.taskmanapp_asg_suspend_policy}"]
  lb_sgs                          = ["${module.taskmanapp_server_lb.lb_sg_id}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.jobs_sg_id}"
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

//The jobapp_lb refers to the taskmanapp load balancer; The reason it's called jobapp is so that we don't exceed the 32 char limit in prod
data "aws_lb" "jobapp_lb" {
  arn  = "${module.taskmanapp_server_lb.lb_id}"
}

resource "aws_route53_record" "taskmanapp_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-taskman"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.jobapp_lb.dns_name}"
    zone_id                = "${data.aws_lb.jobapp_lb.zone_id}"
    evaluate_target_health = true
  }
}

//The jobweb_lb refers to the taskmanweb load balancer; The reason it's called jobweb is so that we don't exceed the 32 char limit in prod

# TaskManWeb DNS
data "aws_lb" "jobweb_lb" {
  arn = "${module.taskmanweb_server_lb.lb_id}"
}

resource "aws_route53_record" "taskmanweb_dns_record" {
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "taskman-${var.fi_name_public}${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.jobweb_lb.dns_name}"
    zone_id                = "${data.aws_lb.jobweb_lb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group_rule" "dbaccess_taskmanapp_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from TaskMan app server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.taskmanapp_server_asg.cluster_sg_id}"
}

# -- DNS --
data "aws_route53_zone" "app_zone" {
  name         = "${data.terraform_remote_state.account_infrastructure.domain_name}."
  private_zone = true
}

data "aws_route53_zone" "app_zone_public" {
  name         = "${data.terraform_remote_state.account_infrastructure.domain_name}."
  private_zone = false
}

# www DNS
data "aws_lb" "www_lb" {
  arn = "${module.www_server_lb.lb_id}"
}

resource "aws_route53_record" "www_dns_record" {
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "${var.fi_name_public}${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.www_lb.dns_name}"
    zone_id                = "${data.aws_lb.www_lb.zone_id}"
    evaluate_target_health = true
  }
}

# svc DNS
data "aws_lb" "svc_lb" {
  arn = "${module.svc_server_lb.lb_id}"
}

# R53 private hosted zone record
resource "aws_route53_record" "svc_dns_record" {
  count   = "${(var.create_r53_private) ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "${var.fi_name_public}-services${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.svc_lb.dns_name}"
    zone_id                = "${data.aws_lb.svc_lb.zone_id}"
    evaluate_target_health = true
  }
}

# R53 private hosted zone record for Imperva CNAME
resource "aws_route53_record" "svc_dns_record_private" {
  count   = "${(var.create_r53_public) ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "${var.fi_name_public}-services${local.region_dns_suffix}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.finserv_svc_imperva_cname}"]
}

# R53 public hosted zone record
resource "aws_route53_record" "svc_dns_record_public" {
  count   = "${(var.create_r53_public) ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.app_zone_public.zone_id}"
  name    = "${var.fi_name_public}-services-public${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.svc_lb.dns_name}"
    zone_id                = "${data.aws_lb.svc_lb.zone_id}"
    evaluate_target_health = true
  }
}

# -- Redis ElastiCache for Session Databases --

resource "aws_security_group" "redis_elasticache_security_group" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sessiondb-sg"
  description = "security group for session database for ${var.fi_name}-${var.environment}"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      "${module.www_server_asg.cluster_sg_id}" # Allows the www EC2 instances to connect to Redis session db
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
}

module "redis_sessiondb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//redis_elasticache"

  replication_group_id          = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sessiondb"
  replication_group_description = "session database for ${var.fi_name}-${var.environment}"
  node_type                     = "${var.redis_elasticache_node_type}"
  replicas_per_node_group       = "${var.redis_elasticache_replicas_per_node_group}"
  num_node_groups               = "${var.redis_elasticache_num_node_groups}"
  subnet_ids                    = ["${data.aws_subnet_ids.private.ids}"]
  security_group_ids            = ["${aws_security_group.redis_elasticache_security_group.id}","${data.terraform_remote_state.account_infrastructure.qualys_sg_id}"]
  engine_version                = "${var.redis_elasticache_engine_version}"
  parameter_group_name          = "${var.redis_parameter_group_name}"
  apply_immediately             = true
  tags                          = "${merge(module.cpt_tags.tags, map("drtier", "3"))}"
}

# -- Redis ElastiCache for Invoice Parser Batch --
resource "aws_elasticache_subnet_group" "redis_invoiceparser_subnet" {
  name       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-invoiceparser-subnet"
  subnet_ids = ["${data.aws_subnet_ids.private.ids}"]
}

resource "aws_elasticache_replication_group" "redis_invoiceparser" {
  replication_group_id          = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-invoiceparser"
  replication_group_description = "Redis database for invoice parser batches for ${var.fi_name}-${var.environment}"
  # multi_az_enabled              = true  # not supported in our Terraform AWS provider, we have 2.70, this requires 3.26
  subnet_group_name             = "${aws_elasticache_subnet_group.redis_invoiceparser_subnet.name}"
  node_type                     = "${var.redis_invoiceparser_node_type}"
  number_cache_clusters         = 2 # = primary + replica
  engine_version                = "${var.redis_invoiceparser_engine_version}"
  parameter_group_name          = "${var.redis_invoiceparser_parameter_group_name}"
  port                          = 6379
  security_group_ids            = ["${aws_security_group.redis_invoiceparser2_sg.id}"]
  automatic_failover_enabled    = true
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  maintenance_window            = "sun:02:00-sun:04:00"
  tags                          = "${merge(module.cpt_tags.tags, map("drtier", "3"))}"
}

# work-around for our Terraform AWS provider not supporting multi_az_enabled setting yet
resource "null_resource" "null_resource_invoiceparser_redis" {
  triggers = {
    cache = "${aws_elasticache_replication_group.redis_invoiceparser.id}"
  }
  provisioner "local-exec" {
    command = "aws elasticache modify-replication-group --replication-group-id ${aws_elasticache_replication_group.redis_invoiceparser.id} --multi-az-enabled --apply-immediately"
  }
}


# -- SQS queues --

# Plog DLQ queue
module "sqs_queue_plogwriterfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriterfailed.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  tags                        = "${module.cpt_tags.tags}"

}

# Plog queue
module "sqs_queue_plogwriter" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriter.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_plogwriterfailed.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# AP DLQ queue
module "sqs_queue_plogwriterfailed_ap" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriterfailed-ap.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  policy                      = ""
  redrive_policy              = ""
  tags                        = "${module.cpt_tags.tags}"
}

# AP queue
module "sqs_queue_plogwriter_ap" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriter-ap.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_plogwriterfailed_ap.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# AP web service request DLQ queue
module "sqs_queue_plogwriterfailed_wsap" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriterfailed-ap-ws.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  policy                      = ""
  redrive_policy              = ""
  tags                        = "${module.cpt_tags.tags}"
}

# AP web service request queue
module "sqs_queue_plogwriter_wsap" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-plogwriter-ap-ws.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  policy                      = ""
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_plogwriterfailed_wsap.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# Account writer DLQ queue
module "sqs_queue_accountwriterfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-accountwriterfailed.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  tags                        = "${module.cpt_tags.tags}"
}

# Account writer queue
module "sqs_queue_accountwriter" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-accountwriter.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_accountwriterfailed.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# Process message writer DLQ queue
module "sqs_queue_processormsgfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-processormsgfailed"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"  
  tags                        = "${module.cpt_tags.tags}"
}

# Process message writer queue
module "sqs_queue_processormsg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-processormsg"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_processormsgfailed.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# Auth DLQ queue
module "sqs_queue_authfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-authfailed"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 691200
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  tags                        = "${module.cpt_tags.tags}"
}

# -------------------------------------
# Auth queue
module "sqs_queue_auth" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-auth"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}" 
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_authfailed.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# IAM policy document attached to the processor server IAM policy
data "aws_iam_policy_document" "processor_server_policy_document" {

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/App*",
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = [
	  "${module.sqs_queue_auth.arn}"
    ]
  }
}

# IAM role policy for processor server to allow SQS access to FI's auth queues
resource "aws_iam_policy" "processor_server_role_policy" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-proc-sqs-policy"
  description = "Allow processor server access to SQS auth queue"
  policy      = "${data.aws_iam_policy_document.processor_server_policy_document.json}"
}

# Attach IAM policy to processor server's IAM role to allow SQS access
resource "aws_iam_role_policy_attachment" "processor_server_role_policy_attachment" {
  role       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-proc-instance-role"
  policy_arn = "${aws_iam_policy.processor_server_role_policy.arn}"
}


# -------------------------------------
# Auth reader DLQ queue - acts as the DLQ for the PARTNER MQ auth queue, there is no corresponding MQ auth queue script here
module "sqs_queue_authreaderfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-authreaderfailed"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 691200
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  tags                        = "${module.cpt_tags.tags}"
}

# Real time account DLQ queue
module "sqs_queue_realtimeaccountfailed" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-rtacctfailed"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  redrive_policy              = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}"
  tags                        = "${module.cpt_tags.tags}"
}

# Real time account queue
module "sqs_queue_realtimeaccountwriter" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sqs_queue"

  queue_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-rtacctwriter"
  fifo_queue                  = false
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  policy                      = ""
  sqs_kms_key                 = "${data.aws_kms_alias.sqs_key.target_key_arn}" 
  redrive_policy              = <<EOF
{
  "deadLetterTargetArn": "${module.sqs_queue_realtimeaccountfailed.arn}",
  "maxReceiveCount": 4
}
EOF
  tags                        = "${module.cpt_tags.tags}"
}

# S3 for SQS messages exceeding max size
resource "aws_s3_bucket" "sqs_overflow_bucket" {
  bucket  = "corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.fi_name}-${var.environment}-sqsoverflow"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${data.aws_kms_alias.s3_key.target_key_arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = false
  }

  tags = "${module.cpt_tags.tags}"
}

resource "aws_s3_bucket_public_access_block" "sqs_overflow_bucket_block" {
  bucket = "${aws_s3_bucket.sqs_overflow_bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}




# -- Custom Extract --
#data "aws_ami" "custext_ami" {
#  most_recent = true
#  owners      = ["111111111114"]
#
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#
#  filter {
#    name   = "name"
#    values = ["CPT-LocalBakery-WIN2019-WinService-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
#  }
#}
#
#data "aws_iam_policy_document" "custext_policy_document" {
#  statement {
#    sid = "s3"
#
#    actions = [
#      "s3:GetBucketLocation",
#      "s3:PutObject",
#      "s3:GetObject",
#      "s3:GetEncryptionConfiguration",
#      "s3:DeleteObjectVersion",
#      "s3:DeleteObject",
#      "s3:AbortMultipartUpload",
#      "s3:ListMultipartUploadParts",
#      "s3:ListBucket",
#      "s3:ListBucketMultipartUploads",
#    ]
#
#    resources = [
#      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-*"
#    ]
#  }
#
#  statement {
#    sid     = "secretsmanager"
#
#    actions = [
#      "secretsmanager:DescribeSecret",
#      "secretsmanager:GetSecretValue",
#    ]
#    resources = [
#      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/${var.fi_name}/*",
#    ]
#  }  
#}
#
#resource "aws_security_group" "winrm_sg" {
#  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-winrm-sg"
#  description = "Security group for custom extracts server connectivity"
#  vpc_id      = "${data.aws_vpc.vpc.id}"
#  tags        = "${module.cpt_tags.tags}"
#
#  ingress = [
#    {
#      description = "Inbound WinRM TCP"
#      from_port   = 5985
#      to_port     = 5986
#      protocol    = "tcp"
#      cidr_blocks = ["${var.winrm_ingress_cidr}"]
#    },
#    {
#      description = "Inbound WinRM UDP"
#      from_port   = 5985
#      to_port     = 5986
#      protocol    = "udp"
#      cidr_blocks = ["${var.winrm_ingress_cidr}"]
#    }
#  ]
#}
#
#module "custext_instance" {
#  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"
#
#  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-custext"
#  hostname                   = "A${lookup(local.region_keys, var.region)}CUSTEX${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
#  ami                        = "${data.aws_ami.custext_ami.id}"
#  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
#  vpc_id                     = "${data.aws_vpc.vpc.id}"
#  instance_type              = "${var.custext_instance_type}"
#  instance_count             = "1"
#  key_name                   = "${var.key_name}"
#  tags                       = "${module.cpt_tags.tags}"
#  ec2_tags                   = "${map("cpm backup", "no-backup")}"
#  fi_name                    = "${var.fi_config}"
#  environment                = "${var.environment}"
#  volume_size                = "${var.custext_volume_size}"
#  ec2on_tag                  = "${var.custext_EC2ON_tag}"
#  ec2off_tag                 = "${var.custext_EC2OFF_tag}"
#  ebs_kms_key_id             = "${data.aws_kms_alias.ebs_key.target_key_arn}"
#  aws_partition_name         = "${data.aws_partition.current.partition}"
#  aws_region_name            = "${data.aws_region.current.name}"
#  aws_region_abbr            = "${lower(lookup(local.region_keys, var.region))}"
#  aws_account_id             = "${data.aws_caller_identity.current.account_id}"
#  dns_domain                 = "${var.dns_domain}"
#  oupath                     = "${var.tier2_oupath}"
#  splunk_egress_cidr         = ["${var.custext_rdp_allow}"]
#  startup_path               = "C:\\CorePlatform\\WinServices"
#  startup_script             = "Startup-CustomExtract.ps1"
#  iam_policy_override_json   = "${data.aws_iam_policy_document.custext_policy_document.json}"
#  dnsServerAddresses         = "${var.dnsServerAddresses}"
#  additional_security_groups  = ["${aws_security_group.winrm_sg.id}"]
#  dependencies                = ["${aws_security_group.winrm_sg.id}"]
#}



# Cerebus access security group
data "aws_security_group" "cerberus_sg_n1_security_group" {
  count = "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerberus-sg-n1"
}

resource "aws_security_group_rule" "cerberus_app_rule" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${data.aws_security_group.cerberus_sg_n1_security_group.id}"
  description              = "Cerberus API from app instance"
  type                     = "ingress"
  from_port                = "${var.cerberus_sg_api_listener_port}"
  to_port                  = "${var.cerberus_sg_api_listener_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.app_server_asg.cluster_sg_id}"
}

# Database access security group
data "aws_security_group" "dbtools_security_group" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-dbtools-sg"
}

resource "aws_security_group" "dbaccess_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbaccess-sg"
  description = "Database access"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
}

resource "aws_security_group_rule" "dbaccess_app_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from App server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.app_server_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "dbaccess_winservices_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from WinSvc server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.winservices_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "dbaccess_logqserver_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from Log Queue server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.logqserver_asg.cluster_sg_id}"
}

resource "aws_security_group_rule" "dbaccess_dbtools_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from DB tools server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${data.aws_security_group.dbtools_security_group.id}"
}

resource "aws_security_group_rule" "dbaccess_dbtools_sqlbrowser_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from DB tools server for SQL browser"
  type                     = "ingress"
  from_port                = 1434
  to_port                  = 1434
  protocol                 = "udp"
  source_security_group_id = "${data.aws_security_group.dbtools_security_group.id}"
}

resource "aws_security_group_rule" "dbaccess_build_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from build servers"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  cidr_blocks              = ["${var.buildserver_ingress_cidr}"]
}

resource "aws_security_group_rule" "dbaccess_icmp_sg_rule" {
  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Allow from entire VPC"
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

resource "aws_security_group_rule" "dbaccess_inbound_ecs_yeti_mod_sg_rule" {
  count                    =  "${(var.ecs_yeti_mod_sg != "")? 1 : 0}" # Create when ecs_yeti_mod_sg is not empty

  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from yeti mod ecs services"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_yeti_mod_sg }"
}

resource "aws_security_group_rule" "dbaccess_inbound_ecs_dsc_mod_sg_rule" {
  count                    =  "${(var.ecs_dsc_mod_sg != "")? 1 : 0}" # Create when ecs_dsc_mod_sg is not empty

  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from dsc mod ecs services"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_dsc_mod_sg }"
}

resource "aws_security_group_rule" "dbaccess_inbound_ecs_prefund_reporting_mod_sg_rule" {
  count                    =  "${(var.ecs_prefund_reporting_mod_sg != "")? 1 : 0}" # Create when ecs_prefund_reporting_mod_sg is not empty

  security_group_id        = "${aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from prefund-reporting mod ecs services"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.ecs_prefund_reporting_mod_sg }"
}

# -- Redis ElastiCache for Invoice Parser Batch --
# This is a circular reference to the batch entry, will fail on the very first run until the batch entry is subsequently run and applied.
data "aws_security_group" "batchtaskman_server_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batchtaskman-sg"
}

resource "aws_security_group" "redis_invoiceparser_security_group" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-redisinvoiceparser-sg"
  description = "Security group for invoice parser batch Redis database for ${var.fi_name}-${var.environment}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

resource "aws_security_group" "redis_invoiceparser2_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-redisinvoiceparser2-sg"
  description = "Security group for invoice parser batch Redis database for ${var.fi_name}-${var.environment} (managed by terraform)"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

## LEAVE THESE AS SEPARATE RULES THAT GET ATTACHED; otherwise, it removes rules that are attached from other entry points (i.e. batch server singles)
resource "aws_security_group_rule" "redis_invoiceparser_old_batch_servers" {
  security_group_id         = "${aws_security_group.redis_invoiceparser2_sg.id}"
  description               = "Allow original batch servers (managed by terraform)"
  type                      = "ingress"
  from_port                 = 6379
  to_port                   = 6379
  protocol                  = "tcp"
  source_security_group_id  = "${data.aws_security_group.batchtaskman_server_sg.id}" # invoice parser writing to Redis
}

resource "aws_security_group_rule" "redis_invoiceparser_logq_servers" {
  security_group_id         = "${aws_security_group.redis_invoiceparser2_sg.id}"
  description               = "Allow original logq servers (managed by terraform)"
  type                      = "ingress"
  from_port                 = 6379
  to_port                   = 6379
  protocol                  = "tcp"
  source_security_group_id  = "${module.logqserver_asg.cluster_sg_id}" # invoice parser writing to Redis
}

resource "aws_security_group_rule" "redis_invoiceparser_default_egress" {
  security_group_id = "${aws_security_group.redis_invoiceparser2_sg.id}"
  description       = "Outbound to VPC (managed by terraform)"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${data.aws_vpc.vpc.cidr_block}"]
}

# DrainSQSToS3 S3 bucket
resource "aws_s3_bucket" "drain_sqs_to_s3_bucket" {
  bucket              = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-sqs-drain-${var.fi_name}-${var.environment}"
  region              = "${var.region}"

  lifecycle_rule {
    id      = "delete after 90 days"
    enabled = true
    expiration {
      days = 90
    }
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_public_access_block" "drain_sqs_block" {
  bucket = "${aws_s3_bucket.drain_sqs_to_s3_bucket.id}"

    block_public_acls       = true
    block_public_policy     = true
    restrict_public_buckets = true
    ignore_public_acls      = true
}

# Outputs
# =================================================
output "redis_id" { value = "${module.redis_sessiondb.id}" }
output "redis_configuration_endpoint_address" { value = "${module.redis_sessiondb.configuration_endpoint_address}" }
output "unhealthy_instance_topic_arn" { value = "${module.unhealthy_instance_topic.topic_arn}" }
output "app_server_lb_sg_id" { value = "${module.app_server_lb.lb_sg_id}" }
output "dbaccess_sg_id" { value = "${aws_security_group.dbaccess_sg.id}" }
output "www_lb_id" { value = "${module.www_server_lb.lb_id}" }
output "svc_lb_id" { value = "${module.svc_server_lb.lb_id}" }
output "svc_sg_id" { value = "${module.svc_server_lb.lb_sg_id}" }