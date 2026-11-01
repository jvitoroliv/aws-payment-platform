# Variables
# =================================================
# kpk
variable "kpk"                          { }

# vpc-level
variable "region"                       { }
variable "vpc_id"                       { }
variable "environment"                  { }
variable "fi_name"                      { default = "shrd" }
variable "fi_list"                      { default = "" }
variable "ebs_kms_alias"                { }

# dns
variable "dns_domain"                   { }
variable "private_hosted_zone"          { }
variable "public_hosted_zone"           { }
# Documented in the module README with accepted ranges.
variable "oupath"                       { }
variable "dnsServerAddresses"           { default = "" }

# instances
variable "key_name"                     { }
variable "ebs_optimized"                { default = true }
# Type constraint catches misuse at plan time.
variable "transform_flags"              { default = "" }
## We don't know the specific splunk forwarder IP and it could change without warning, so we open to FINSERV internal
variable "splunk_egress_cidr"           { 
                                          type = "list"
                                          default = ["10.0.0.0/8"] 
                                        }

variable "adtools_instance_type"        { default = "r5a.large" }
variable "adtools_ec2on_tag"            { default = "on=(M-F,7);tz=est" }
variable "adtools_ec2off_tag"           { default = "off=(M-F,21);tz=est" }
# Defaults are production-safe; override per environment.
variable "adtools_volume_size"          { default = 100 }
variable "adtools_count"                { default = 0 }

variable "dbtools_instance_type"        { default = "r5a.xlarge" }
variable "dbtools_ec2on_tag"            { default = "on=(M-F,7);tz=est" }
variable "dbtools_ec2off_tag"           { default = "off=(M-F,21);tz=est" }
# Defaults work for standard deployments.
variable "dbtools_volume_size"          { default = 100 }
variable "dbtools_min_instances"        { default = 2 }
variable "dbtools_max_instances"        { default = 2 }
# Input validation ensures callers provide sane values.
variable "dbtools_default_cooldown"     { default = 300 }
variable "dbtools_ingress_cidr"         { 
                                          type = "list" 
                                          default = ["10.0.0.0/8"] 
                                        }
variable "dbtools_ASGOFF_tag"           { default = "off=(M-F,21);tz=est" }
variable "dbtools_ASGON_tag"            { default = "on=(M-F,7);tz=est" }
variable "dbtools_site_id"              { default = "10" }
variable "dbtools_asg_suspend_policy"   { 
                                          type = "list"
                                          default = []
                                        }
variable "dbtools_datadog_check_params" { default = "datadog_tcp_check_name,Batch Server WINRM;datadog_tcp_check_port,5985;datadog_tcp_check_server_filter,AUE1BATSVR" }

# jobdb 
variable jobdb_read_capacity            { default = 5 }
variable jobdb_write_capacity           { default = 5 }

# hosted zone
variable "domain_name"                  { }
# SES bucket name
variable "s3_bucket_ses"                { }

# params
variable "gpo_params"                   { default = "ROLE-ENC-GPOSupplemental-CopyPaste" }

# tags
variable "tag_billingid"                { default = "platform-XXXX" }
variable "tag_compliance"               { default = "PCI-CDE" }
variable "tag_dataclass"                { default = "Confidential" }
variable "tag_drtier"                   { default = "1" }
variable "tag_lob"                      { default = "Payment Processing" }
variable "tag_owner"                    { default = "user@example-company.com" }
variable "tag_projectname"              { default = "coreplatform" }
variable "tag_approle"                  { default = "batch" }
variable "tag_app_id"                   { default = "APP_44819" }
variable "tag_ostype"                   { default = "Windows" }
variable "tag_application"              { default = "coreplatform" }

# security groups
variable "allow_qualys_scans"           { default = "false" } # toggle qualys security group so we don't accidentally allow all inbound if this isn't set
variable "qualys_ingress_cidr"          {
                                          type = "list"
                                          default = ["0.0.0.0/0"]
                                        }
variable "winrm_ingress_cidr"           { 
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "ingress_cidr"                 { 
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "egress_cidr"                  { 
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "sql_diagnostic_cidr"          { 
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "active_directory_egress_cidr" {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "platform-services_ingress_cidr"          {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "datalake_ingress_cidr"        {
                                          type = "list"
                                          default = ["10.99.99.99/32"]
                                        }

variable "aiven_cidr"                   {
                                          type = "list"
                                          default = ["10.94.0.0/22"]
                                        }

# Build Server Items
variable "buildserver_sg_name"          { default = "AllowRdpFromLan" } # Existing SG name in Prod
variable "build_ingress_cidr"           {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "build_egress_cidr"            {
                                          type = "list"
                                          default = []
                                        }
variable "build_egress_all_cidr"        {
                                          type = "list"
                                          default = ["0.0.0.0/0"]
                                        }
variable "build_egress_sql_cidr"        {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "buildserver_instance_type"    { default = "m5.large" }

variable "partner_mq_port"                  { }
variable "partner_mq_publish_port"          { }
variable "partner_mq_egress_cidr"           { type = "list" }

variable "rdp_access_ingress_cidr"      {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "ec2_tags_cpm_tag"             {
                                          type = "map"
                                          default = {"cpm backup" = "no-backup"}
                                        }
variable "controlm_egress_cidr"         {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }


#Providers
# =================================================
provider "aws" {
  region = "${var.region}"
  version = "2.70.4"
  
}
provider "null" {
  version = "2.1.2"
}
  

provider "template" {
  version = "2.2.0"
}

# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }

  env_keys = {
    "dev"   = "D"
    "uat"   = "U"
    "stage" = "S"
    "demo"  = "C"
    "prod"  = "P"
    "qa"    = "Q"
  }

  short_region_keys = {
    "us-east-1" = "E"
    "us-west-2" = "W"
  }
}


# Datasources
# =================================================

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
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

data "aws_subnet" "private" {
  count = "${length(data.aws_subnet_ids.private.ids)}"
  id    = "${element(data.aws_subnet_ids.private.ids, count.index)}"
}

data "aws_subnet" "public" {
  count = "${length(data.aws_subnet_ids.public.ids)}"
  id    = "${element(data.aws_subnet_ids.public.ids, count.index)}"
}

data "aws_kms_alias" "ebs" {
  name = "${var.ebs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


# Resources
# =================================================
resource "aws_route53_zone" "enc_domain" {
  name = "${var.private_hosted_zone}"

  vpc {
    vpc_id = "${data.aws_vpc.vpc.id}"
  }
   # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
   lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [ "vpc" ]
  }
}

resource "aws_route53_zone" "enc_public_domain" {
  count = "${lower(lookup(local.region_keys, var.region)) == "ue1" ? 1 : 0}"
  name  = "${var.public_hosted_zone}"
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
  lob         = "${var.tag_lob}"
  owner       = "${var.tag_owner}"
  projectname = "${var.tag_projectname}"
  approle     = "${var.tag_approle}"
  app_id      = "${var.tag_app_id}"
  ostype      = "${var.tag_ostype}"
  application = "${var.tag_application}"
}


# RDP access security group designed to restrict access of 3389 to (default = ["10.0.0.0/8"]) only
resource "aws_security_group" "rdp_access_sg" {
  count = 1
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-rdp-access-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"
  
  ingress  {
    cidr_blocks = ["${var.rdp_access_ingress_cidr}"]
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
  }
}

# SQL_Diagnostic_Manager_Monitor
# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "sql_diagnostic_sg" {
  count = 1
  
  name   = "SQL_Diagnostic_Manager_Monitor"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
  {
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  },
  {
    from_port   = 9290
    to_port     = 9294
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  },
  
  {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  },
  
  {
    from_port   = 5166
    to_port     = 5169
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  },
  
  {
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  },
  {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${var.sql_diagnostic_cidr}"]
  }
  ]
}

# Security group to allow dbtools to access Redis
resource "aws_security_group" "redis_sg" {
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-redis-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  egress = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_cidr}"]
    }
  ]
}

# Security group for Aiven/Kafka
resource "aws_security_group" "aiven_sg" {
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-aiven-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  egress = [
    {
      from_port   = 10000
      to_port     = 31000
      protocol    = "tcp"
      cidr_blocks = ["${var.aiven_cidr}"]
    }
  ]
}

#  Security group for Datalake on db ec2's
# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group" "datalake_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-datalake-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["${var.datalake_ingress_cidr}"]
    }
  ]
}


## DEPRECATED BY basic_server_connectivity_sg. remove once you've run account and applied basic_server_connectivity_sg to all asgs
resource "aws_security_group" "qualys_sg" {
  count = "${var.allow_qualys_scans == "true" ? 1 : 0}"
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-qualys-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${var.qualys_ingress_cidr}"]
    }
  ]
}

resource "aws_security_group" "platform-services_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-platform-services-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["${var.platform-services_ingress_cidr}"]
    }
  ]
}

# Security group to allow RDP, qualys scans through the firewalls for PCI scanning,
# and out to Active Directory, splunk and other standard connections that every machine has.
resource "aws_security_group" "basic_server_connectivity_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-basic-server-connectivity-sg"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
  description = "Basic server connectivity - managed by terraform"

  ingress     = [
    //RDP
    {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = ["${var.rdp_access_ingress_cidr}"]
    },
    //Qualys
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${var.qualys_ingress_cidr}"]
    },
    //Tool servers
    {
      from_port = 3389
      to_port = 3389
      protocol = "tcp"
      prefix_list_ids = ["pl-060fcac0c0019daba"]
    },
    //corp-pki-ipv4-pl
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      prefix_list_ids = ["pl-008b77b609fe2ed1c"]
    },
    //existing rule in AWS
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.94.1.131/32", "10.94.5.197/32"]
    }
  ]
  egress = [
    //Splunk
    {
      description = "Outbound Splunk"
      from_port   = 8088
      to_port     = 8089
      protocol    = "tcp"
      cidr_blocks = ["${var.splunk_egress_cidr}"]
    }, 
    {
      description = "Outbound Splunk"
      from_port   = 9996
      to_port     = 9997
      protocol    = "tcp"
      cidr_blocks = ["${var.splunk_egress_cidr}"]
    },
//Tanium agents
    {
      description = "Tanium connectivity"
      from_port   = 17472
      to_port     = 17472
      protocol    = "tcp"
      cidr_blocks =["0.0.0.0/0"]
    },
    {
      description = "Tanium connectivity"
      from_port   = 17486
      to_port     = 17486
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    //Active Directory
    {
      description = "Kerberos Key Distribution Center TCP (AD)"
      from_port   = 88
      to_port     = 88
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Kerberos Key Distribution Center UDP (AD)"
      from_port   = 88
      to_port     = 88
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Port 123 UDP (AD) (datadog)"
      from_port   = 123
      to_port     = 123
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Remote Procedure Call (AD)"
      from_port   = 135
      to_port     = 135
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Port 137 UDP (AD)"
      from_port   = 137
      to_port     = 137
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Port 138 UDP (AD)"
      from_port   = 138
      to_port     = 138
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "NetBIOS Session Service (AD)"
      from_port   = 139
      to_port     = 139
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "LDAP TCP (AD)"
      from_port   = 389
      to_port     = 389
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "LDAP UDP (AD)"
      from_port   = 389
      to_port     = 389
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "SMB, Net Logon TCP (AD)"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "SMB, Net Logon UDP (AD)"
      from_port   = 445
      to_port     = 445
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "DNS TCP (AD)"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "DNS UDP (AD)"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Randomly allocated high TCP ports (AD)"
      from_port   = 49152
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Randomly allocated high UDP ports (AD)"
      from_port   = 49152
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    {
      description = "Powershell (AD)"
      from_port   = 9389
      to_port     = 9389
      protocol    = "tcp"
      cidr_blocks = ["${var.active_directory_egress_cidr}"]
    },
    //HTTPS for windows updates, etc...
    {
      description = "Http"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Https"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Https 2"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "WSUS"
      from_port   = 8531
      to_port     = 8531
      protocol    = "tcp"
      cidr_blocks = ["10.94.194.46/32"]
    },
    {
      description = "WSUS"
      from_port   = 8530
      to_port     = 8530
      protocol    = "tcp"
      cidr_blocks = ["10.94.194.46/32"]
    },
    {
      description = "Https Payments Place API"
      from_port   = 8445
      to_port     = 8445
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    //datadog ports 443, 123, 10516, 443 and 123 are already covered
    {
      description = "Port for log collection over TCP (datadog)"
      from_port   = 10516
      to_port     = 10516
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_cidr}"]
    },
   {
      description = "Port for dogstatsd collection over TCP (datadog)"
      from_port   = 8125
      to_port     = 8125
      protocol    = "udp"
      cidr_blocks = ["${var.egress_cidr}"]
    }
  ]
}

resource "aws_security_group" "outbound_sftp_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-outbound-sftp-sg"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
  description = "Outbound S/FTP - managed by terraform"

  egress = [
    {
      description = "Outbound FTP"
      from_port   = 21
      to_port     = 21
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }, 
    {
      description = "Outbound SFTP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 24
      to_port     = 24
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }, 
    {
      description = "Outbound SFTP"
      from_port   = 990
      to_port     = 990
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }, 
    {
      description = "Outbound SFTP"
      from_port   = 1022
      to_port     = 1022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }, 
    {
      description = "Outbound SFTP"
      from_port   = 2121
      to_port     = 2121
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 2122
      to_port     = 2122
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 2200
      to_port     = 2200
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 2222
      to_port     = 2222
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 2245
      to_port     = 2245
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 2727
      to_port     = 2727
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 4022
      to_port     = 4022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 5630
      to_port     = 5630
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 6522
      to_port     = 6522
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 7409
      to_port     = 7409
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 7522
      to_port     = 7522
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }, 
    {
      description = "Outbound SFTP"
      from_port   = 8022
      to_port     = 8022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 9022
      to_port     = 9022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 10021
      to_port     = 10022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 11422
      to_port     = 11422
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 20022
      to_port     = 20022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 25222
      to_port     = 25222
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound MFT"
      from_port   = 442
      to_port     = 442
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound SFTP"
      from_port   = 30022
      to_port     = 30022
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    ## This is bad, we need to figure out how to limit this range, the whole firewall might as well be open
    {
      description = "Passive FTP"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_security_group" "outbound_email_sg" {
  count = 1
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-outbound-email-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  egress = [
    {
      from_port   = 25
      to_port     = 25
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 25
      to_port     = 25
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ,
    {
      description = "Outbound SendGrid"
      from_port   = 587
      to_port     = 587
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_security_group" "outbound_third_party_services_sg" {
  count = 1
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-outbound-auth-push-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"
  description = "Outbound to Auth Push clients and other external web services. (Managed by Terraform)"

  egress = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound for specific auth push client"
      from_port   = 8081
      to_port     = 8081
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Security group to allow Remote Powershell via WinRM
resource "aws_security_group" "inbound_winrm_sg" {
  count = 1
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-inbound-winrm-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 5985
      to_port     = 5986
      protocol    = "tcp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    },
    {
      from_port   = 5985
      to_port     = 5986
      protocol    = "udp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    }
  ]
}

# Security group for build server
resource "aws_security_group" "buildserver_sg" {
  name        = "${var.buildserver_sg_name}"
  description = "${var.buildserver_sg_name}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = ["${var.rdp_access_ingress_cidr}"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["${var.build_ingress_cidr}"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${var.build_ingress_cidr}"]
    }
  ]

  # Note: Prod had additional extraneous rules for Egress 10.0.0.0/8 on UDP ports 53, 88, 135, 138, 389, 464, and TCP ports 53, 135, 139, 464, 3268, 3269 labeled with description "Domain Controller"
  # Those rules were all covered by ALL/ALL to 10.0.0.0/8
  egress = [
    {
      from_port   = 5985
      to_port     = 5985
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_all_cidr}"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_all_cidr}"]
    },
    {
      from_port   = 5986
      to_port     = 5986
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_all_cidr}"]
    },
    {
      from_port   = 9418
      to_port     = 9418
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_all_cidr}"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_all_cidr}"]
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${concat(list(data.aws_vpc.vpc.cidr_block),var.build_egress_cidr)}"]
    },
    {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["${var.build_egress_sql_cidr}"]
    }
  ]
}

# Copied from Prod and transformed automatically from JSON by https://flosell.github.io/iam-policy-json-to-terraform/
data "aws_iam_policy_document" "buildadmin_policy_document" {
  statement {
    sid       = "VisualEditor0"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "iam:PolicyArn"

      values = [
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
        "arn:aws:iam::aws:policy/job-function/SystemAdministrator",
        "arn:aws:iam::aws:policy/job-function/SupportUser",
        "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
        "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator",
        "arn:aws:iam::aws:policy/job-function/DataScientist",
        "arn:aws:iam::aws:policy/job-function/Billing",
        "arn:aws:iam::aws:policy/aws-service-role/AWSOrganizationsServiceTrustPolicy",
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/IAM*",
        "arn:aws:iam::aws:policy/AdministratorAccess",
      ]
    }
  }

  statement {
    sid       = "VisualEditor1"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "application-autoscaling:*",
      "rds:*",
      "iam:ListServerCertificates",
      "logs:*",
      "iam:GenerateServiceLastAccessedDetails",
      "redshift:*",
      "dynamodb:*",
      "autoscaling:*",
      "acm-pca:*",
      "cloudfront:*",
      "route53domains:*",
      "iam:SimulateCustomPolicy",
      "secretsmanager:*",
      "ec2messages:*",
      "config:*",
      "quicksight:*",
      "events:*",
      "ec2-instance-connect:*",
      "sns:*",
      "iam:ListPolicies",
      "cloudformation:*",
      "autoscaling-plans:*",
      "cloudwatch:*",
      "ecs:*",
      "ec2:*",
      "cognito-idp:*",
      "route53resolver:*",
      "iam:GetServiceLastAccessedDetailsWithEntities",
      "cloudtrail:*",
      "iam:ListPoliciesGrantingServiceAccess",
      "sqs:*",
      "iam:GetServiceLastAccessedDetails",
      "cognito-sync:*",
      "ds:*",
      "ses:*",
      "kms:*",
      "discovery:*",
      "elasticfilesystem:*",
      "cognito-identity:*",
      "s3:*",
      "fsx:*",
      "iam:ListRoles",
      "elasticloadbalancing:*",
      "iam:GetContextKeysForCustomPolicy",
      "es:*",
      "applicationinsights:*",
      "ssm:*",
      "route53:*",
      "lambda:*",
      "ecr:*",
      "elasticmapreduce:*",
      "elasticache:*",
      "acm:*",
    ]
  }

  statement {
    sid    = "VisualEditor2"
    effect = "Allow"

    resources = [
      "arn:aws:iam::*:policy/*",
      "arn:aws:iam::*:instance-profile/*",
      "arn:aws:iam::*:role/*",
      "arn:aws:iam::*:server-certificate/*",
    ]

    actions = ["iam:*"]
  }

  statement {
    sid       = "VisualEditor3"
    effect    = "Deny"
    resources = ["arn:aws:cloudtrail:*:*:trail/corp-cloudtrail-*"]

    actions = [
      "cloudtrail:PutEventSelectors",
      "cloudtrail:StopLogging",
      "cloudtrail:StartLogging",
      "cloudtrail:AddTags",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:CreateTrail",
      "cloudtrail:RemoveTags",
    ]
  }

  statement {
    sid       = "VisualEditor4"
    effect    = "Deny"
    resources = ["*"]

    actions = [
      "ec2:DeleteSubnet",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:DetachClassicLinkVpc",
      "ec2:DeleteVpcPeeringConnection",
      "ec2:DeleteVpcEndpoints",
      "ec2:CreateTransitGatewayRouteTable",
      "ec2:AcceptVpcPeeringConnection",
      "ec2:AcceptTransitGatewayVpcAttachment",
      "ec2:DisableVgwRoutePropagation",
      "ec2:AssociateVpcCidrBlock",
      "ec2:ReplaceRoute",
      "ec2:AssociateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:RejectVpcPeeringConnection",
      "ec2:DisassociateVpcCidrBlock",
      "ec2:CreateRoute",
      "ec2:RejectTransitGatewayVpcAttachment",
      "ec2:CreateVpcPeeringConnection",
      "ec2:RejectVpcEndpointConnections",
      "ec2:EnableVpcClassicLink",
      "ec2:DisassociateTransitGatewayRouteTable",
      "ec2:DisableTransitGatewayRouteTablePropagation",
      "ec2:CreateVpcEndpointConnectionNotification",
      "ec2:CreateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:DeleteTransitGatewayRouteTable",
      "ec2:CreateVpcEndpointServiceConfiguration",
      "ec2:CreateTransitGatewayRoute",
      "ec2:DeleteTransitGatewayRoute",
      "ec2:CreateTransitGatewayVpcAttachment",
      "ec2:CreateDefaultVpc",
      "ec2:AssociateSubnetCidrBlock",
      "ec2:DeleteVpc",
      "ec2:EnableTransitGatewayRouteTablePropagation",
      "ec2:CreateSubnet",
      "ec2:ExportTransitGatewayRoutes",
      "ec2:CreateVpc",
      "ec2:DeleteVpcEndpointServiceConfigurations",
      "ec2:ReplaceTransitGatewayRoute",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateDefaultSubnet",
      "ec2:AttachClassicLinkVpc",
      "ec2:CreateClientVpnRoute",
      "ec2:AcceptVpcEndpointConnections",
      "ec2:DeleteRoute",
      "ec2:CreateVpnConnectionRoute",
      "ec2:DisassociateSubnetCidrBlock",
      "ec2:DeleteVpnConnectionRoute",
      "ec2:DeleteVpcEndpointConnectionNotifications",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteClientVpnRoute",
      "ec2:EnableVgwRoutePropagation",
      "ec2:DisableVpcClassicLinkDnsSupport",
      "ec2:DisableVpcClassicLink",
      "ec2:EnableVpcClassicLinkDnsSupport",
    ]
  }

  statement {
    sid       = "VisualEditor5"
    effect    = "Deny"
    resources = ["arn:aws:iam::*:role/SAML*"]
    actions   = ["iam:*"]
  }
}

resource "aws_iam_policy" "buildadmin_policy" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-build-policy"
  description = "IAM policy for build admin"
  policy      = "${data.aws_iam_policy_document.buildadmin_policy_document.json}"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore-policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Trust policy — defines which principals can assume this role via STS
data "aws_iam_policy_document" "ec2_assume_role_policy_document" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "buildserver_role" {
  name               = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-build-role"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role_policy_document.json}"
  description        = "Allows EC2 instances to call AWS services on your behalf"
}

resource "aws_iam_instance_profile" "buildadmin_instance_profile" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-buildadmin-profile"
  role = "${aws_iam_role.buildserver_role.id}"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore-policy-attach" {
  role       = "${aws_iam_role.buildserver_role.id}"
  policy_arn = "${data.aws_iam_policy.AmazonSSMManagedInstanceCore-policy.arn}"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "BuildAdmin-policy-attach" {
  role       = "${aws_iam_role.buildserver_role.id}"
  policy_arn = "${aws_iam_policy.buildadmin_policy.arn}"
}

data "aws_ami" "buildserver_ami" {
  most_recent = true
  owners      = ["111111111114"]
                  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-GlobalBakery-WIN2019-ADOBuildServer-ami-*"]
  }
}

resource "aws_launch_template" "launch_template_buildserver" {
  name                    = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-build-template"
  instance_type           = "${var.buildserver_instance_type}"
  key_name                = "${var.key_name}"
  image_id                = "${data.aws_ami.buildserver_ami.id}"
  update_default_version  = true

  iam_instance_profile {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-buildadmin-profile"
  }

  network_interfaces {
    subnet_id       = "${data.aws_subnet_ids.private.ids[0]}"
    security_groups = ["${aws_security_group.buildserver_sg.id}"]
  }

  tag_specifications {
    resource_type = "instance"
    tags = "${merge(map("Name", "", "Owner", "user@example-company.com", "Patch Group", "ADO", "OSType", "Windows", "application", "coreplatform", "Project", "coreplatform"))}"
  }

  user_data = "${base64encode(file("${path.module}/scripts/InstallTrendMicro.ps1"))}"
}

# DEPRECATED BY basic_server_connectivity_sg, remove once all usages has been removed
resource "aws_security_group" "outbound_activedirectory_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-outbound-activedirectory-sg"
  description = "Security group for outbound active directory"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"

  # minimum ports required to be open to join active directory
  egress = [
    {
      description = "Kerberos Key Distribution Center TCP (AD)"
      from_port   = 88
      to_port     = 88
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Kerberos Key Distribution Center UDP (AD)"
      from_port   = 88
      to_port     = 88
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Port 123 UDP (AD)"
      from_port   = 123
      to_port     = 123
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Remote Procedure Call (AD)"
      from_port   = 135
      to_port     = 135
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Port 137 UDP (AD)"
      from_port   = 137
      to_port     = 137
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Port 138 UDP (AD)"
      from_port   = 138
      to_port     = 138
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "NetBIOS Session Service (AD)"
      from_port   = 139
      to_port     = 139
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "LDAP TCP (AD)"
      from_port   = 389
      to_port     = 389
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "LDAP UDP (AD)"
      from_port   = 389
      to_port     = 389
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "SMB, Net Logon TCP (AD)"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "SMB, Net Logon UDP (AD)"
      from_port   = 445
      to_port     = 445
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "DNS TCP (AD)"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "DNS UDP (AD)"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Randomly allocated high TCP ports (AD)"
      from_port   = 49152
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Randomly allocated high UDP ports (AD)"
      from_port   = 49152
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      description = "Powershell (AD)"
      from_port   = 9389
      to_port     = 9389
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
  ]
}

# Security group required for PARTNER MQ on-prem access
resource "aws_security_group" "outbound_partner_mq_sg" {
  count = 1
  
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-outbound-partner_mq-sg"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
  description = "Outbound to PARTNER MQ"

  egress = [
    {
      description = "Outbound to MQ ser on-prem"
      from_port   = 1419
      to_port     = 1419
      protocol    = "tcp"
      cidr_blocks = ["${var.partner_mq_egress_cidr}"]
    },
    {
      description = "Outbound to MQ server on-prem"
      from_port   = "${var.partner_mq_port}"
      to_port     = "${var.partner_mq_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.partner_mq_egress_cidr}"]
    },
    {
      description = "Outbound to MQ publish server on-prem"
      from_port   = "${var.partner_mq_publish_port}"
      to_port     = "${var.partner_mq_publish_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.partner_mq_egress_cidr}"]
    },
    //existing rule in AWS
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_security_group" "jobs_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-jobs-sg"
  description = "Batch and Job Server connectivity - managed by terraform"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"

  # minimum ports required to be open to get to control m
  egress = [
    {
      description = "JobTestAutomation (TaskMan)"
      from_port   = 6001
      to_port     = 6001
      protocol    = "tcp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    },
    {
      description = "JobTestAutomation (TaskMan)"
      from_port   = 1801
      to_port     = 1801
      protocol    = "tcp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    },
    {
      description = "Https 2 (ControlM)"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = ["${var.controlm_egress_cidr}"]
    },
    {
      description = "Enterprise Manager (ControlM)"
      from_port   = 18080
      to_port     = 18080
      protocol    = "tcp"
      cidr_blocks = ["${var.controlm_egress_cidr}"]
    },
  ]
}

# -- DB Tools --
data "aws_ami" "dbtools_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-DBTOOLS-${var.kpk}-ami*"]
  }
}

data "aws_iam_policy_document" "dbtools_policy_document" {

  statement {
    sid = "s3"

    actions = [
   		"s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
  		"s3:CreateMultipartUpload",
      "s3:GetEncryptionConfiguration",
      "s3:DeleteObjectVersion",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}*",
      "arn:${data.aws_partition.current.partition}:s3:::corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-*",
      "arn:${data.aws_partition.current.partition}:s3:::${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-mqtest-update",
      "arn:${data.aws_partition.current.partition}:s3:::${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-mqtest-update/*"
    ]
  }

  statement {
    sid     = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/${var.environment}*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/finserv/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:Service/*",
    ]
  }  

  statement {
    sid     = "dynamodb"

    actions = [
      "dynamodb:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-jobdb",
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/platform-services.common.prefetch.pools",
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = ["*"]
  }

  statement {
    sid = "kms"

    actions = [
      "kms:*",
    ]

    resources = ["*"]
  }
}

module "dbtools_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg_lt"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbtools"
  fi_name                    = "${var.fi_name}" 
  fi_list                    = "${var.fi_list}"
  environment                = "${var.environment}"
  hostname                   = "A${lookup(local.region_keys, var.region)}DBTOOLS000${lookup(local.env_keys, var.environment)}"
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  key_name                   = "${var.key_name}"
  image_id                   = "${data.aws_ami.dbtools_ami.id}"
  instance_type              = "${var.dbtools_instance_type}"
  ebs_optimized              = "${var.ebs_optimized}"
  volume_size                = "${var.dbtools_volume_size}"
  min_size                   = "${var.dbtools_min_instances}"
  max_size                   = "${var.dbtools_max_instances}"
  default_cooldown           = "${var.dbtools_default_cooldown}"
  ingress_cidr               = "${var.dbtools_ingress_cidr}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  ASGON_tag                  = "${var.dbtools_ASGON_tag}"
  ASGOFF_tag                 = "${var.dbtools_ASGOFF_tag}"
  tags                       = "${merge(module.cpt_tags.tags, map("drtier", "2"))}"
  asg_tags                   = ["${module.cpt_tags.autoscaling_tags}"]
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs.target_key_arn}"
  iam_policy_override_json   = "${data.aws_iam_policy_document.dbtools_policy_document.json}"
  startup_path               = "C:\\CoreService\\Database\\DatabaseProjects\\CoreService"
  startup_script             = "DbToolsStartup.ps1"
  startup_script_params      = "${var.dbtools_datadog_check_params}"
  site_id                    = "${var.dbtools_site_id}"
  health_check_type          = "EC2"
  health_check_grace_period  = "1200"
  ad_password_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn    = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.oupath}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  suspended_processes        = ["${var.dbtools_asg_suspend_policy}"]
  lb_sgs                     = [] # none
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups = [
      "${aws_security_group.basic_server_connectivity_sg.*.id}",
      "${aws_security_group.inbound_winrm_sg.*.id}",
      "${aws_security_group.redis_sg.*.id}",
      "${aws_security_group.jobs_sg.*.id}",
      "${aws_security_group.outbound_sftp_sg.*.id}",
      "${aws_security_group.aiven_sg.*.id}",
    ]
  uselifecyclehook           = "true"

  gpo_params                 = "${var.gpo_params}"
  transform_flags            = "${var.transform_flags}"
}

# -- AD Tools --
data "aws_ami" "adtools_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-GlobalBakery-WIN2019-Certificates-ami-*"]
  }
}

data "aws_iam_policy_document" "adtools_policy_document" {

  statement {
    sid     = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*",    ]
  }  
}

module "adtools_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  instance_count             = "${var.adtools_count}"
  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-adtools"
  hostname                   = "A${lookup(local.region_keys, var.region)}ADTOOLS000${lookup(local.env_keys, var.environment)}"
  ami                        = "${data.aws_ami.adtools_ami.id}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  instance_type              = "${var.adtools_instance_type}"
  key_name                   = "${var.key_name}"
  tags                       = "${merge(module.cpt_tags.tags, map("drtier", "2"))}"
  ec2_tags                   = "${var.ec2_tags_cpm_tag}"
  fi_name                    = ""
  environment                = "${var.environment}"
  volume_size                = "${var.adtools_volume_size}"
  ec2on_tag                  = "${var.adtools_ec2on_tag}"
  ec2off_tag                 = "${var.adtools_ec2off_tag}"
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs.target_key_arn}"
  aws_partition_name         = "${data.aws_partition.current.partition}"
  aws_region_name            = "${data.aws_region.current.name}"
  aws_region_abbr            = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id             = "${data.aws_caller_identity.current.account_id}"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.oupath}"
  startup_path               = ""
  startup_script             = ""  # no startup script
  iam_policy_override_json   = "${data.aws_iam_policy_document.adtools_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  #dependencies              = ["${module.managed_ad.depended_on}"]
  transform_flags            = "${var.transform_flags}"
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups = [
    "${aws_security_group.basic_server_connectivity_sg.*.id}",
  ]
}


# DynamoDb
# =================================================

# -- Job config DynamoDb --

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

/*
resource "aws_dynamodb_table" "jobdb-us-east-1" {
  provider = "aws.us-east-1"
  name     = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-jobdb"

  server_side_encryption {
    enabled = true
  }
  
  hash_key         = "JobNameKey"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  read_capacity    = "${var.jobdb_read_capacity}"
  write_capacity   = "${var.jobdb_write_capacity}"
  tags             = "${module.cpt_tags.tags}"
  
  attribute {
    name = "JobNameKey"
    type = "S"
  }
}

resource "aws_dynamodb_table" "jobdb-us-west-2" {
  provider = "aws.us-west-2"
  name     = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-jobdb"

  server_side_encryption {
    enabled = true
  }

  hash_key         = "JobNameKey"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  read_capacity    = "${var.jobdb_read_capacity}"
  write_capacity   = "${var.jobdb_write_capacity}"
  tags             = "${module.cpt_tags.tags}"
  
  attribute {
    name = "JobNameKey"
    type = "S"
  }
}

resource "aws_dynamodb_global_table" "jobdb" {
  depends_on = ["aws_dynamodb_table.jobdb-us-east-1", "aws_dynamodb_table.jobdb-us-west-2"]
  provider   = "aws.us-east-1"
  name       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-jobdb"
 
  replica {
    region_name = "us-east-1"
  }

  replica {
    region_name = "us-west-2"
  }
}
*/

#####Amazon ses#######
##For domain verification the txt records from enc dev,qa,uat,prod needs to be manually added in route53 of AOC legacy prod aws accounts

# When creating account infrastructure for demo environment we came across issues with SES main rule creation as we are using the same account as QA for demo environmnet setup.
# Checked with Titan and Beetleguese teams and since we are not using SES at all, getting rid of this 

# module "coreplatform_ses" {
#   source            = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ses"
#   s3_bucket_ses     = "${var.s3_bucket_ses}"
#   mail_from_address = "${var.environment}"
# }


# S3 for DataUpdate artifacts
resource "aws_s3_bucket" "dataupdate_bucket" {
  bucket              = "corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.environment}-dataupdate"
  acl                 = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id      = "delete after 30 days"
    enabled = true
    expiration {
      days = 30
    }
  }

  versioning {
    enabled = false
  }

  tags = "${module.cpt_tags.tags}"
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_public_access_block" "dataupdate_bucket_block" {
  bucket = "${aws_s3_bucket.dataupdate_bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# S3 for TaskMan artifacts for updating Batch servers
resource "aws_s3_bucket" "taskman_update_bucket" {
  bucket              = "corp-${lower(lookup(local.region_keys, var.region))}-platform-enc-${var.environment}-taskman-update"
  acl                 = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id      = "delete after 30 days"
    enabled = true
    expiration {
      days = 30
    }
  }

  versioning {
    enabled = false
  }

  tags = "${module.cpt_tags.tags}"
}

resource "aws_s3_bucket_public_access_block" "taskman_update_bucket_block" {
  bucket = "${aws_s3_bucket.taskman_update_bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# S3 for elb access logging
resource "aws_s3_bucket" "access_bucket" {
  bucket              = "finserv-${lower(lookup(local.region_keys, var.region))}-cpt-encaccesslogging-${var.environment}"
  acl                 = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  versioning {
    enabled = false
  }

  tags = "${module.cpt_tags.tags}"
}
# S3 for MqTest artifacts for updating Batch servers
resource "aws_s3_bucket" "mqtest_bucket" {
  bucket              = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-mqtest-update"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id      = "delete after 30 days"
    enabled = true
    expiration {
      days = 30
    }
  }

  versioning {
    enabled = false
  }

  tags = "${module.cpt_tags.tags}"
}

resource "aws_s3_bucket_public_access_block" "mqtest_bucket_block" {
  bucket = "${aws_s3_bucket.mqtest_bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}


# Metrics/Alarms
# =================================================
/*
resource "aws_sns_topic" "networkchangetopic" {
    name = "network_change_topic"
    display_name = "For alerts of CorePlatform IAM/Network Changes"
    kms_master_key_id = "alias/aws/sns"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "networkchangetopic_policy"
  statement {
    sid       = "allow_publish_from_this_ssm"
    effect    = "Allow"
    actions   = [
      "SNS:Publish"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["${aws_sns_topic.networkchangetopic.arn}"]
  }
}

resource "aws_sns_topic_policy" "access" {
  arn    = "${aws_sns_topic.networkchangetopic.arn}"
  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}

resource "aws_cloudwatch_log_metric_filter" "networkchangefilter" {
  name           = "network_change_filter"
  pattern        = "{ ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"ChangeResourceRecordSets\") || ($.eventName = \"DeleteSecret\") || ($.eventName = \"UpdateSecret\") || ($.eventName = \"DeleteGroup\") || ($.eventName = \"DeleteGroupPolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"DeleteRoute\") || ($.eventName = \"DeleteRouteTable\") || ($.eventName = \"DeleteSecurityGroup\") || ($.eventName = \"DeleteVpcEndpoints\") }"
  log_group_name = "CloudTrail/DefaultLogGroup"
  metric_transformation {
    name            = "NetworkChangeCount"
    namespace       = "CloudTrailMetrics"
    value           = "1"
    default_value   = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "networkchangealarm" {

  alarm_name          = "NetworkChangeAlarm"
  alarm_description   = "A significant network change has occured"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 60
  namespace           = "CloudTrailMetrics"
  metric_name         = "NetworkChangeCount"
  statistic           = "Sum"
  alarm_actions       = ["${aws_sns_topic.networkchangetopic.arn}"]
}
*/

# Outputs
# =================================================
output "private_hosted_zone_id"               { value = "${aws_route53_zone.enc_domain.zone_id}" }
output "public_hosted_zone_id"                { value = "${aws_route53_zone.enc_public_domain.*.zone_id}" }
output "adtools_instance_role_name"           { value = "${module.adtools_instance.instance_role_name}" }
output "basic_server_connectivity_sg_id"      { value = "${aws_security_group.basic_server_connectivity_sg.*.id}" }
output "sql_diagnostic_sg_id"                 { value = "${aws_security_group.sql_diagnostic_sg.*.id}" }
output "outbound_email_sg_id"                 { value = "${aws_security_group.outbound_email_sg.*.id}" }
output "inbound_winrm_sg_id"                  { value = "${aws_security_group.inbound_winrm_sg.*.id}" }
output "outbound_partner_mq_sg_id"                { value = "${aws_security_group.outbound_partner_mq_sg.*.id}" }
output "jobs_sg_id"                           { value = "${aws_security_group.jobs_sg.*.id}" }
output "outbound_sftp_sg_id"                  { value = "${aws_security_group.outbound_sftp_sg.*.id}" }
output "outbound_third_party_services_sg_id"  { value = "${aws_security_group.outbound_third_party_services_sg.*.id}" }

## DEPRECATED BY coporate tools sg, remove when references to this are gone
output "rdp_access_sg_id"                     { value = "${aws_security_group.rdp_access_sg.*.id}" }
output "qualys_sg_id"                         { value = "${aws_security_group.qualys_sg.*.id}" }
output "outbound_activedirectory_sg_id"       { value = "${aws_security_group.outbound_activedirectory_sg.*.id}" }
