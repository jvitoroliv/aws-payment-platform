
# Inter-Module Dependency
# ==============================================
// Dependency getter hack for chaining module dependencies together.
// Ref:  https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607

resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}

resource "null_resource" "dependency_setter" {
  depends_on = ["aws_directory_service_directory.directory_service"]
}


# Directory Service
# ==============================================

resource "aws_directory_service_directory" "directory_service" {
  name     = "${var.directory_name}"
  password = "${var.directory_password}"
  edition  = "${var.directory_edition}"
  type     = "${var.directory_type}"

  vpc_settings {
    vpc_id     = "${var.vpc_id}"
    subnet_ids = ["${var.subnet_ids}"]
  }

  tags = "${merge(map("Name", format("%s", var.directory_name)), var.tags)}"

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = ["password"]
  }

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}


# IAM
# ==============================================

data "aws_iam_policy_document" "ec2-assume-role-policy" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# TODO: Review to ensure not too permissive
data "aws_iam_policy_document" "ad_domain_policy_document" {
  statement {
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:CreateAssociation",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeInstanceStatus",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ds:CreateComputer",
      "ds:DescribeDirectories",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }

  statement {
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
      "*",
    ]
  }
}

resource "aws_iam_role" "domain_computer_role" {
  name               = "${replace(var.directory_name, ".", "-")}-DomainComputerRole"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role-policy.json}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "aws_iam_policy" "domain_computer_policy" {
  name = "${replace(var.directory_name, ".", "-")}-DomainComputerPolicy"
  policy = "${data.aws_iam_policy_document.ad_domain_policy_document.json}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "aws_iam_role_policy_attachment" "domain_computer_policy_attach" {
  role       = "${aws_iam_role.domain_computer_role.id}"
  policy_arn = "${aws_iam_policy.domain_computer_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "domain_computer_awsssmcore_policy_attach" {
  role       = "${aws_iam_role.domain_computer_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "domain_computer_awsssmdca_policy_attach" {
  role       = "${aws_iam_role.domain_computer_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "aws_iam_instance_profile" "domain_computer_profile" {
  name = "${replace(var.directory_name, ".", "-")}-DomainComputer"
  role = "${aws_iam_role.domain_computer_role.name}"
}


# SSM Configuration
# ==============================================

data "template_file" "ssm_domain_join_json_tpl" {
  template = "${file("${path.module}/templates/ssm-domain-join.tpl.json")}"

  vars {
    directory_id           = "${aws_directory_service_directory.directory_service.id}"
    directory_name         = "${var.directory_name}"
    ec2_ssm_domain_join_ou = "${var.ec2_ssm_domain_join_ou}"
    primary_dns            = "${aws_directory_service_directory.directory_service.dns_ip_addresses[0]}"
    secondary_dns          = "${aws_directory_service_directory.directory_service.dns_ip_addresses[1]}"
  }
}

resource "aws_ssm_document" "ssm_document" {
  content       = "${data.template_file.ssm_domain_join_json_tpl.rendered}"
  document_type = "Command"
  name          = "${replace(var.directory_name, ".", "-")}-ssm-domain-join"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

