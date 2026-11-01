aiven_schema_registry_port = 26868
aws_account_number         = "222222222222"
aws_private_subnets        = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
aws_public_subnets         = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
aws_region                 = "us-west-2"
aws_vpc_id                 = "vpc-0example000000001"
base_url                   = "platform.example.com"
core_services_cidr         = "10.94.4.0/22"
dc2_network = [
  "198.51.100.1/32", "198.51.100.1/32", "198.51.100.1/32", "198.51.100.1/20", "198.51.100.1/32", "198.51.100.1/32",
  "198.51.100.1/32", "198.51.100.1/32", "198.51.100.1/32"
]
dd_tag_cardinality                         = "orchestrator"
dns_zone_id                                = "Z0EXAMPLE000000"
email_domain                               = "prod.platform.example.com"
environment                                = "prod"
ingress_allowlists_api_alb                 = ["prod-tag-api-public-alb-ingress"]
ingress_allowlists_api_internal_alb        = ["prod-tag-api-internal-alb-ingress"]
ingress_allowlists_web_alb                 = ["prod-tag-web-public-alb-ingress"]
ingress_allowlists_web_internal_alb        = ["prod-tag-web-internal-alb-ingress"]
ingress_allowlists_common_api_alb          = ["prod-tag-common-api-public-alb-ingress"]
ingress_allowlists_common_api_internal_alb = ["prod-tag-common-api-internal-alb-ingress"]
internal_ssl_cert_arn                      = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: platform.example.com, *.platform.example.com and *.internal.platform.example.com
public_ssl_cert_arn                        = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: platform.example.com and *.platform.example.com
sftp_vpc_endpoint_id                       = "vpce-06bfac5ae3948e812"

internal_sftp_publickeys = [
  {
    name      = "tag-sftp-verify"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
    //ALLOW_THIS_LINE
  },
  {
    name      = "visaftprod"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visaftprod"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visaftprod"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visaftprod"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visaftprod"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  }
]

internal_sftp_users = [
  {
    name    = "tag-sftp-verify",
    homedir = "tag-sftp-verify"
  },
  {
    name    = "visaftprod",
    homedir = "visa-in-clearing"
  }
]

finserv_job_count            = 4
job_card_migration_count = 4
api_cpu                  = 8192
api_memory               = 61440
api_min_capacity         = 4
