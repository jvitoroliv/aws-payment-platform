# main.tf
# Manages primary resource definitions resources.

data "aws_vpc" "this_vpc" {
  id = var.vpc_id
}

resource "aws_iam_role" "aws_sftp_logging_role" {
  name               = format("%s_%s_aws_sftp_logging_role", var.region, var.environment)
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = file("${path.module}/policies/aws-sftp-logging-role.json")
}

resource "aws_iam_role_policy" "aws_sftp_logging_role_has_full_cloudwatch_access" {
  name   = format("%s_%s_aws_sftp_logging_role_has_full_cloudwatch_access", var.region, var.environment)
  role   = aws_iam_role.aws_sftp_logging_role.id
  policy = file("${path.module}/policies/aws-sftp-cloudwatch-access.json")
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "aws_ftp_iam_role" {
  name               = format("%s_%s_aws_ftp_iam_role", var.region, var.environment)
  assume_role_policy = file("${path.module}/policies/aws-ftp-iam-role-policy.json")
}

resource "aws_iam_role_policy" "aws_ftp_full_access_to_s3_sftp_bucket" {
  name   = format("%s_%s_aws_ftp_full_access_to_S3", var.region, var.environment)
  role   = aws_iam_role.aws_ftp_iam_role.id
  policy = <<END_OF_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": ["arn:aws:s3:::${var.s3bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:GetObjectVersion",
        "s3:GetObjectACL",
        "s3:PutObjectACL"
      ],
      "Resource": ["arn:aws:s3:::${var.s3bucket}/*"]
    }
  ]
}
END_OF_POLICY
}

resource "aws_security_group" "sftp" {
  name        = format("%s-%s-sftp", var.region, var.environment)
  vpc_id      = var.vpc_id
  description = "Security Group for AWS SFTP Server"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = flatten([concat(tolist([data.aws_vpc.this_vpc.cidr_block]), var.client_network)])

  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle { create_before_destroy = true }
  tags = {
    Service = "sftp"
  }
}

resource "aws_security_group" "sftp_endpoint" {
  count       = length(var.allowed_cidrs) > 0 ? 1 : 0
  name        = format("%s-%s-sftp-endpoint", var.region, var.environment)
  vpc_id      = var.vpc_id
  description = "Security Group for AWS SFTP Server Endpoint"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs

  }
  lifecycle { create_before_destroy = true }
  tags = {
    Service = "sftp"
  }
}

resource "aws_vpc_endpoint_security_group_association" "this" {
  count             = length(var.allowed_cidrs) > 0 ? 1 : 0
  vpc_endpoint_id   = var.vpc_endpoint_id
  security_group_id = aws_security_group.sftp_endpoint[0].id
}

resource "aws_transfer_server" "internal-sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.aws_sftp_logging_role.arn
  endpoint_type          = "VPC_ENDPOINT"

  endpoint_details {
    vpc_endpoint_id = var.vpc_endpoint_id
  }

  tags = {
    NAME     = format("%s-%s-%s", var.environment, var.region, "internal-sftp")
    Service  = "sftp"
    Internal = true
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_transfer_user" "internal-users" {
  count          = length(var.internal-users)
  server_id      = aws_transfer_server.internal-sftp.id
  user_name      = lookup(var.internal-users[count.index], "name")
  role           = aws_iam_role.aws_ftp_iam_role.arn
  home_directory = "/${var.s3bucket}/${lookup(var.internal-users[count.index], "homedir")}"
  tags = {
    Service = "sftp"
  }
  policy = file("${path.module}/policies/aws-ftp-user-policy.json")
}

resource "aws_transfer_ssh_key" "internal-publickeys" {
  count     = length(var.internal-publickeys)
  server_id = aws_transfer_server.internal-sftp.id
  user_name = lookup(var.internal-publickeys[count.index], "name")
  body      = lookup(var.internal-publickeys[count.index], "publickey")
  depends_on = [
    aws_transfer_user.internal-users
  ]
}

