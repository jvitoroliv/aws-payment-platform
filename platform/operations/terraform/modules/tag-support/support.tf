# support.tf
# Part of the support Terraform configuration module.

resource "aws_instance" "support" {
  ami                    = data.aws_ami.aws_linux.id
  iam_instance_profile   = aws_iam_instance_profile.support_instance_region_role.name
  instance_type          = var.instance_type
  subnet_id              = var.aws_subnet_id
  user_data              = file("${path.module}/init/startup")
  vpc_security_group_ids = [aws_security_group.support_box.id]

  root_block_device {
    delete_on_termination = var.delete_on_termination
    volume_size           = var.volume_size
    volume_type           = var.volume_type
  }

  tags = {
    Name             = "Support.${var.environment}"
    Temporary        = "true"
    Role             = "Support"
    EC2ON            = "on=(M-U,0);tz=est"
    billingid        = "CORP-XXXXX-XXXX-XXXXX"
    owner            = "user@example-company.com"
    approle          = "worker"
    appid            = "Support.${var.environment}"
    cas-patching-utc = "cattle"
  }
  volume_tags = {
    Name      = "Support.${var.environment}-volume"
    Temporary = "true"
    Role      = "Support"
    EC2ON     = "NONE"
    EC2OFF    = "NONE"
    billingid = "CORP-XXXXX-XXXX-XXXXX"
    owner     = "user@example-company.com"
    approle   = "worker"
    appid     = "Support.${var.environment}"
  }
}

resource "aws_security_group" "support_box" {
  vpc_id      = var.vpc_id
  name        = format("%s-support-box-sg", var.environment)
  description = "Allow egress from from support box"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    # Allow outbound traffic to Postgres
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-support-box-sg", var.environment)
  }
}

resource "aws_iam_instance_profile" "support_instance_region_role" {
  name = "temp_${var.environment}_${var.aws_region}_support_instance_role"
  role = aws_iam_role.support_instance_region_role.name
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "support_instance_region_role" {
  name               = "temp_${var.environment}_${var.aws_region}_support_instance_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "support_instance_perms_to_support_instance_region" {
  role       = aws_iam_role.support_instance_region_role.name
  policy_arn = aws_iam_policy.support_instance_perms.arn
}

resource "aws_iam_policy" "support_instance_perms" {
  name        = "temp_${var.environment}_${var.aws_region}_support_instance_perms"
  path        = "/"
  description = "support instance policy"
  policy      = data.aws_iam_policy_document.minimal_instance_perms.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "AmazonEC2RoleforSSM" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
data "aws_iam_policy_document" "minimal_instance_perms" {
  source_policy_documents = [
    data.aws_iam_policy.AmazonSSMManagedInstanceCore.policy,
    data.aws_iam_policy.AmazonEC2RoleforSSM.policy
  ]

  // add statements here to override AmazonSSMManagedInstanceCore with more permissive/restrictive statements
  // temporarily added this unnecessary statement to work around an error
  // Error: data.aws_iam_policy_document.minimal_instance_perms: "statement": required field is not set
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_acct_id}:parameter/env.${var.environment}/role.all/*"
    ]
  }
  // Allow instance to generate data key to encrypted session data
  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.aws_acct_id}:key/*"
    ]
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
