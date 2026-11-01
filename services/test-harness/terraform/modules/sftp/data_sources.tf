# data_sources.tf
# Manages data source lookups resources.

data "aws_region" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.shared_bucket
    dynamodb_table = "tag-subprod-state-store"
    key            = "shared-${local.shared_region}-${var.environment}.tfstate"
    region         = data.aws_region.current.name
  }
}

data "aws_ami" "aws_linux" {
  most_recent = true
  owners      = ["111111111110"]

  filter {
    name   = "name"
    values = ["finserv--amazon-linux-2-finservprodr*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
