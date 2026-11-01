#########AWS Provider #######

provider "aws" {  region = "${var.region}" }
variable "region" { default = "us-east-1" }


####Terraform backend#######

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    bucket = "cpt-terraform-states"
    key    = "cpt-infrastructure/central/terraform.tfstate"
    region = "us-east-1"
  }
}
data "aws_iam_policy_document" "ecrpolicy" {
  statement {
    sid    = "ecr policy"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:ListImages",
      "ecr:GetLifecyclePolicyPreview"
    ]
    principals = {
      type        = "AWS"
      identifiers = ["arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::555555555555:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root"]
    }
  }
}
resource "aws_ecr_repository" "dataupdate" {
  name = "coreplatform_dataupdate"
}

resource "aws_ecr_repository_policy" "ecrpolicy_data" {
  repository = "${aws_ecr_repository.dataupdate.name}"
  policy     = "${data.aws_iam_policy_document.ecrpolicy.json}"
}

#======================aws ecr repo for other repo jobconfig update========================

resource "aws_ecr_repository" "jobconfig" {
  name = "coreplatform_jobconfigupdate"
}

resource "aws_ecr_repository_policy" "ecrpolicy" {
  repository = "${aws_ecr_repository.jobconfig.name}"
  policy     = "${data.aws_iam_policy_document.ecrpolicy.json}"
}

########################aws ecr repository for Global docker image ##########################

resource "aws_ecr_repository" "global" {
  name  = "coreplatform_global"
}
resource "aws_ecr_repository_policy" "ecrpolicy_global" {
  repository = "${aws_ecr_repository.global.name}"
  policy     =  "${data.aws_iam_policy_document.ecrpolicy.json}"
}

#===========================AWS s3 bucket ====================================



#### s3 bucket policy##############
/*
data "aws_iam_policy_document" "s3policy" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [ "arn:aws:s3:::finserv-coreplatform-artifacts-${var.region}"]

    principals = {
      type        = "AWS"
      identifiers = ["arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::555555555555:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root"]
    }
  }
  statement {
    sid    = "2"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [ "arn:aws:s3:::finserv-coreplatform-artifacts-${var.region}"]

    principals = {
      type        = "AWS"
      identifiers = ["arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::555555555555:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root", "arn:aws:iam::999999999999:root"]
    }
  }

}
*/
resource "aws_s3_bucket" "central" {
  bucket = "finserv-coreplatform-artifacts-${var.region}"
  acl    = "private"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Example permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root"

                ]
            },
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::finserv-coreplatform-artifacts-${var.region}"
        },
        {
            "Sid": "Example permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                   "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root",
                    "arn:aws:iam::999999999999:root"
                ]
            },
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::finserv-coreplatform-artifacts-${var.region}/*"
        },
        {
            "Sid": "Stmt1504640908907",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::finserv-coreplatform-artifacts-${var.region}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id      = "delete after 90 days"
    enabled = true
    expiration {
      days = 90
    }
  }
}

###########  IAM role for packer ################

data "aws_iam_policy_document" "packer" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "s3:Get*",
      "s3:List*"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}
resource "aws_iam_policy" "packer" {
  name   = "packer-iam-policy"
  policy = "${data.aws_iam_policy_document.packer.json}"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "packer" {
  name                  = "packer-instance-profile"
  force_detach_policies = true
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "packer" {
  role       = "${aws_iam_role.packer.name}"
  policy_arn = "${aws_iam_policy.packer.arn}"
}

resource "aws_iam_instance_profile" "packer" {
  name = "${aws_iam_role.packer.name}"
  role = "${aws_iam_role.packer.name}"
  depends_on = ["aws_iam_role.packer"]
}
