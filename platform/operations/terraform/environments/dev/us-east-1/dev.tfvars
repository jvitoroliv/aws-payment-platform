aiven_schema_registry_port = 13443
aws_account_number         = "111111111111"
aws_private_subnets        = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
aws_public_subnets         = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
aws_region                 = "us-east-1"
aws_vpc_id                 = "vpc-0example000000001"
base_url                   = "dev.platform.example.com"
chronos_api                = "https://mock-us-east-1-dev.platform.example.com/mock-chronos"
core_services_cidr         = "10.94.0.0/22"
dc2_network = [
  "198.51.100.10/32", "198.51.100.11/32", "198.51.100.12/32", "10.200.1.0/24", "198.51.100.13/32"
]
dd_tag_cardinality                         = "orchestrator"
dns_zone_id                                = "Z0EXAMPLE000000"
email_domain                               = "dev.platform.example.com"
environment                                = "dev"
ingress_allowlists_api_alb                 = ["dev-tag-api-public-alb-ingress"]
ingress_allowlists_api_internal_alb        = ["dev-tag-api-internal-alb-ingress"]
ingress_allowlists_web_alb                 = ["dev-tag-web-public-alb-ingress"]
ingress_allowlists_web_internal_alb        = ["dev-tag-web-internal-alb-ingress"]
ingress_allowlists_common_api_alb          = ["dev-tag-common-api-public-alb-ingress"]
ingress_allowlists_common_api_internal_alb = ["dev-tag-common-api-internal-alb-ingress"]
internal_sftp_publickeys = [
  {
    name      = "tag-sftp-verify"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visadev"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  }
]
internal_sftp_users = [
  {
    name    = "tag-sftp-verify",
    homedir = "tag-sftp-verify"
  },
  {
    name    = "visadev",
    homedir = "visadev"
  }
]
internal_ssl_cert_arn = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: *.internal.dev.platform.example.com and *.platform.example.com
public_ssl_cert_arn   = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: *.dev.platform.example.com and *.platform.example.com
sftp_vpc_endpoint_id  = "vpce-07fad8c1caefb5ca1"
finserv_job_count         = 2
