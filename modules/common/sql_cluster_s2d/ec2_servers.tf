# Suggestion: break the looping controls on resources related to the "secondary" nodes so there are 3 statically defined nodes. This would simplify the code. 


# Instance Profile Role & Policies 
# ---------------------------------------------------------------------
data "aws_iam_policy_document" "instance_profile_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "instance_profile_role" {
  name               = "${var.svr_name_prefix}-role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = "${data.aws_iam_policy_document.instance_profile_assume_role.json}"
}

resource "aws_iam_instance_profile" "sql_server_instance_profile" {
  name = "${var.svr_name_prefix}-profile"
  role = "${aws_iam_role.instance_profile_role.name}"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = "${aws_iam_role.instance_profile_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "attach_full_ssm_policy" {
  role       = "${aws_iam_role.instance_profile_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy_document" "read_from_automation_s3_buckets" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.automation_scripts_bucket}",
      "arn:aws:s3:::${var.sql_server_iso_bucket}",
      "arn:aws:s3:::${var.sql_server_backups_bucket}",
      "arn:aws:s3:::${var.coreplatform_artifacts_bucket}"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject*"
    ]
    resources = [
      "arn:aws:s3:::${var.automation_scripts_bucket}/*",
      "arn:aws:s3:::${var.sql_server_iso_bucket}/*",
      "arn:aws:s3:::${var.sql_server_backups_bucket}/*",
      "arn:aws:s3:::${var.coreplatform_artifacts_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "read_from_automation_s3_buckets" {
  name   = "read_from_automation_s3_buckets"
  role   = "${aws_iam_role.instance_profile_role.id}"
  policy = "${data.aws_iam_policy_document.read_from_automation_s3_buckets.json}"
}

data "aws_iam_policy_document" "write_ssm_logs_to_s3" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.automation_scripts_bucket}/logs/ssm/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*" ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "write_ssm_logs_to_s3" {
  name   = "write_ssm_logs_to_s3"
  role   = "${aws_iam_role.instance_profile_role.id}"
  policy = "${data.aws_iam_policy_document.write_ssm_logs_to_s3.json}"
}

# Allow instances to read AD and SQL credentials from Secrets Manager
data "aws_iam_policy_document" "read_secrets_mgr" {
  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "${var.ad_password_secrets_arn}",
      "${var.ad_username_secrets_arn}",
      "${var.sql_svcacct_creds_secrets_arn}",
      "${var.sql_login_creds_secrets_arn}"
    ]
  }
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "read_secrets_mgr" {
  name   = "read_ad_and_sql_creds_from_secrets_mgr"
  role   = "${aws_iam_role.instance_profile_role.id}"
  policy = "${data.aws_iam_policy_document.read_secrets_mgr.json}"
}

# User Data Templates
# ---------------------------------------------------------------------
data "template_file" "userdata_primary" {
  template = "${file("${path.module}/scripts/userdata.ps1")}"

  vars {
    hostname             = "${replace(var.hostname_format, "xxx", "001")}"
    coreplatform_env        = "${var.environment}"
    coreplatform_fi         = "${var.enc_fi}"
    dns_domain           = "${var.domain_dns_name}"
    oupath               = "${var.oupath}"
    ssm_config           = "${var.win_cluster_name}-ssm-primary-server-config"
  }
}

data "template_file" "userdata_secondary" {
  count = "${var.num_of_secondary_nodes}"

  template = "${file("${path.module}/scripts/userdata.ps1")}"

  vars {
    hostname             = "${ replace(var.hostname_format, "xxx", format("%03d", count.index + 2) ) }"
    coreplatform_env        = "${var.environment}"
    coreplatform_fi         = "${var.enc_fi}"
    dns_domain           = "${var.domain_dns_name}"
    oupath               = "${var.oupath}"
    ssm_config           = "${var.win_cluster_name}-ssm-secondary-server-config-${count.index + 1}"
  }
}


# ENIs with multiple IP addresses
# ---------------------------------------------------------------------

resource "aws_network_interface" "primary_server_eni" {
  subnet_id         = "${element(var.subnet_ids, 0)}"
  security_groups   = ["${aws_security_group.sql_server.id}"]
  description       = "Primary ENI for EC2 instance with SQL Server in AZ #1"
  private_ips_count = 2  # 2 secondary IPs in addition to the primary
  
  tags = "${merge(var.tags, map("Name", format("%s-1", var.svr_name_prefix)))}"
}

resource "aws_network_interface" "secondary_server_eni" {
  count             = "${var.num_of_secondary_nodes}"

  subnet_id         = "${element(var.subnet_ids, count.index + 1)}"
  security_groups   = ["${aws_security_group.sql_server.id}"]
  description       = "Primary ENI for EC2 instance with SQL Server in AZ #${count.index + 2}"
  private_ips_count = 2  # 2 secondary IPs in addition to the primary
  
  tags = "${merge(var.tags, map("Name", format("%s-%d", var.svr_name_prefix, count.index + 2)))}"
}



# EC2 Instances for SQL Server cluster 
# ---------------------------------------------------------------------

resource "aws_instance" "primary_server" {
  ami                  = "${var.ami}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.sql_server_instance_profile.name}"
  user_data            = "${data.template_file.userdata_primary.rendered}"

  root_block_device = 
  [
    {
      volume_size = "${var.root_vol_size}"
    },
  ]


  # Set device_index to 0 to make it eth0 (primary on the instance)
  network_interface {
    network_interface_id = "${aws_network_interface.primary_server_eni.id}"
    device_index         = 0
  }

  tags = "${merge(var.tags, map("Name", replace(var.name_format, "xxx", "001"), "Hostname", replace(var.hostname_format, "xxx", "001"), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [ "ami"]
  }

  disable_api_termination = "true"  # Instance termination protection

}


resource "aws_instance" "secondary_server" {
  count = "${var.num_of_secondary_nodes}"

  ami                  = "${var.ami}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.sql_server_instance_profile.name}"
  user_data            = "${element(data.template_file.userdata_secondary.*.rendered, count.index)}"

  root_block_device = 
  [
    {
      volume_size = "${var.root_vol_size}"
    },
  ]

  # Set device_index to 0 to make it eth0 (primary on the instance)
  network_interface {
    network_interface_id = "${element(aws_network_interface.secondary_server_eni.*.id, count.index)}"
    device_index         = 0
  }

  tags = "${merge(var.tags, map("Name", replace(var.name_format, "xxx", format("%03d", count.index + 2) ), "Hostname", replace(var.hostname_format, "xxx", format("%03d", count.index + 2) ), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"

  lifecycle {
    # Ignored fields are managed by external controllers (auto-scaler, CI/CD).
    ignore_changes = [ "ami"]
  }

  disable_api_termination = "true"  # Instance termination protection

}
