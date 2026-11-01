# Variables
# -----------------------------------------------------------------------
# Type constraint catches misuse at plan time.
variable "name" {}

variable "fi_name" {}

variable "fi_list" {
  default = ""
}

variable "environment" {}
variable "hostname" {}
variable "vpc_id" {}
# Input validation ensures callers provide sane values.
variable "key_name" {}
variable "image_id" {}
variable "instance_type" {}
variable "ebs_optimized" {}
variable "volume_size" {}
# Defaults are production-safe; override per environment.
variable "min_size" {}
variable "max_size" {}
variable "default_cooldown" {}

variable "health_check_grace_period" {
  default = 300
}

variable "health_check_type" {}

# Documented in the module README with accepted ranges.
variable "ingress_cidr" {
  type = "list"
}

variable "default_egress_cidr" {
  type    = "list"
  default = ["0.0.0.0/0"]
}

variable "active_directory_egress_cidr" {
  type    = "list"
  default = ["10.0.0.0/8"]
}

variable "splunk_egress_cidr" {
  type    = "list"
  default = ["10.0.0.0/8"]
}

variable "lb_sgs" {
  type = "list"
}

variable "lb_from_port" {
  default = 80
}

variable "lb_to_port" {
  default = 80
}

variable "subnet_ids" {
  type = "list"
}

variable "scale_in_adjustment" {
  default = "-1"
}

variable "scale_out_adjustment" {
  default = "1"
}

variable "autoscale_notification_ng_topic_arn" {
  default = ""
}

variable "autoscale_notification_ok_topic_arn" {
  default = ""
}

variable "log_retention" {
  default = 30
}

variable "autoscale_cooldown" {
  default = 300
}

variable "ASGON_tag" {
  default = "on=(M-F,7);tz=est"
}

variable "ASGOFF_tag" {
  default = "on=(M-F,21);tz=est"
}

variable "tags" {
  type = "map"
}

variable "asg_tags" {
  type = "list"
}

variable "iam_policy_override_json" {
  default = "null"
}

variable "target_group_arns" {
  type    = "list"
  default = []
}

variable "startup_path" {
  default = ""
}

variable "startup_script" {
  default = ""
}

variable "startup_script_params" {
  default = ""
}

variable "gpo_params" {
  default = ""
}

variable "transform_flags" {
  default = ""
}

variable "site_id" {
  default = ""
}

variable "ad_password_secrets_arn" {}
variable "ad_username_secrets_arn" {}

variable "uselifecyclehook" {
  default = "false"
}

variable "lifecyclehook_timeout" {
  default = 3600
}

variable "dns_domain" {}
variable "oupath" {}

#datadog_enable is a string type to make the powershell translation easier, i'm tired of trying different things
variable "datadog_enable" {
  default = "true"
}

variable "dnsServerAddresses" {
  default = ""
}

variable "suspended_processes" {
  type    = "list"
  default = []
}

variable "scale_out_alarms" {
  type = "list"

  default = [
    {
      name               = "CPUReservation-High"
      description        = "Scale out pushed by high reservation"
      operator           = "GreaterThanOrEqualToThreshold"
      evaluation_periods = 1
      metric_name        = "CPUReservation"
      namespace          = "AWS/AutoScaling"
      period             = 300
      statistic          = "Average"
      threshold          = 75
    },
  ]
}

variable "scale_in_alarms" {
  type = "list"

  default = [
    {
      name               = "CPUReservation-Low"
      description        = "Scale in pushed by low reservation"
      operator           = "LessThanThreshold"
      evaluation_periods = 1
      metric_name        = "CPUReservation"
      namespace          = "AWS/AutoScaling"
      period             = 300
      statistic          = "Average"
      threshold          = 25
    },
  ]
}

variable "scale_in_ok_actions" {
  type    = "list"
  default = []
}

variable "scale_out_ok_actions" {
  type    = "list"
  default = []
}

variable "ebs_kms_key_id" {
  default = ""
}

variable "override_security_group_id" {
  default = ""
}

variable "has_override_security_group_id" {
  default = false
}

variable "additional_security_groups" {
  type    = "list"
  default = []
}

variable "dependencies" {
  description = "A list of module dependencies"
  default     = []
  type        = "list"
}

# Dependencies
# =================================================
resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}

locals {
  drtier = "${lookup(var.tags, "drtier")}"

  launch_template_tags = "${merge(
  map("Name", "${var.name}"), 
  map("ASGON", var.ASGON_tag), 
  map("Hostname","${var.hostname}"), 
  map("ASGOFF",  var.ASGOFF_tag), 
  map("Hostname","${var.hostname}"), 
  map("drtier","${local.drtier}"),
  map("billingid","${lookup(var.tags, "billingid")}"),
  map("compliance","${lookup(var.tags, "compliance")}"),
  map("dataclass","${lookup(var.tags, "dataclass")}"),
  map("environment","${lookup(var.tags, "environment")}"),
  map("lob","${lookup(var.tags, "lob")}"),
  map("owner","${lookup(var.tags, "owner")}"),
  map("project","${lookup(var.tags, "project")}"),
  map("approle","${lookup(var.tags, "approle")}"),
  map("appid","${lookup(var.tags, "appid")}"),
  map("application","${lookup(var.tags, "application")}"),
  map("ostype","${lookup(var.tags, "ostype")}"),
  map("FI","${lookup(var.tags, "FI")}"),
  map("EC2ON","on=(M-U,0);tz=est"),
  )}"
}

# Group Infrastructure
# -----------------------------------------------------------------------
data "aws_iam_policy_document" "instance_policy" {
  override_json = "${var.iam_policy_override_json}"

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ds:CreateComputer",
      "ds:DescribeDirectories",
      "ec2:Describe*",
      "s3:GetEncryptionConfiguration",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "${var.ad_password_secrets_arn}",
      "${var.ad_username_secrets_arn}",
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
      "autoscaling:CompleteLifecycleAction",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "instance_role" {
  name                  = "${var.name}-instance-role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy    = "${data.aws_iam_policy_document.assume_role.json}"
  force_detach_policies = true
  tags                  = "${var.tags}"
}

resource "aws_iam_role_policy" "instance_policy" {
  name   = "${var.name}-instance-policy"
  role   = "${aws_iam_role.instance_role.id}"
  policy = "${data.aws_iam_policy_document.instance_policy.json}"
}

# SSM policy attachment
# =================================================
data "aws_iam_policy" "AmazonSSMManagedInstanceCore-policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore-policy-instance-attach" {
  role       = "${aws_iam_role.instance_role.id}"
  policy_arn = "${data.aws_iam_policy.AmazonSSMManagedInstanceCore-policy.arn}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-profile"
  role = "${aws_iam_role.instance_role.id}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group" "instance_sg" {
  # Do not create this security group if an override is provided
  count = "${var.has_override_security_group_id ? 0 : 1}"

  name   = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"

  ingress = [
    {
      description     = "Inbound HTTP from LB"
      from_port       = "${var.lb_from_port}"
      to_port         = "${var.lb_to_port}"
      protocol        = "tcp"
      security_groups = ["${var.lb_sgs}"]
    },
  ]

  egress = [
    {
      description = "Outbound all"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${var.default_egress_cidr}"]
    },
    {
      //remove these after you apply basic_server_connectivity_sg
      description = "Outbound Splunk"
      from_port   = 8089
      to_port     = 8089
      protocol    = "tcp"
      cidr_blocks = ["${var.splunk_egress_cidr}"]
    },
    {
      description = "Outbound Splunk"
      from_port   = 9997
      to_port     = 9997
      protocol    = "tcp"
      cidr_blocks = ["${var.splunk_egress_cidr}"]
    },
  ]

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

data "template_file" "userdata_asg" {
  template = "${file("${path.module}/template/userdata.ps1")}"

  vars {
    coreplatform_env         = "${var.environment}"
    coreplatform_fi          = "${var.fi_name}"
    coreplatform_filist      = "${var.fi_list}"
    hostname              = "${var.hostname}"
    dns_domain            = "${var.dns_domain}"
    dnsServerAddresses    = "${var.dnsServerAddresses}"
    oupath                = "${var.oupath}"
    startup_path          = "${var.startup_path}"
    startup_script        = "${var.startup_script}"
    startup_script_params = "${var.startup_script_params}"
    coreplatform_siteid      = "${var.site_id}"
    gpo_params            = "${var.gpo_params}"
    transform_flags       = "${var.transform_flags}"
    datadog_enable        = "${var.datadog_enable}"
  }
}

resource "aws_launch_configuration" "launch_config" {
  name_prefix          = "${var.name}-"
  security_groups      = ["${concat(list(var.has_override_security_group_id ? var.override_security_group_id : aws_security_group.instance_sg.id), var.additional_security_groups)}"]
  key_name             = "${var.key_name}"
  image_id             = "${var.image_id}"
  instance_type        = "${var.instance_type}"
  ebs_optimized        = "${var.ebs_optimized}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.id}"
  user_data            = "${data.template_file.userdata_asg.rendered}"
  enable_monitoring    = true

  root_block_device {
    volume_size = "${var.volume_size}"
    encrypted   = "${var.ebs_kms_key_id == "" ? false : true}"

    // Setting this key is not currently supported. The device will be encrypted using the default aws/ebs key
    // kms_key_id  = "${var.ebs_kms_key_id}"
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "aws_launch_template" "launch_template" {
  name_prefix            = "${var.name}"
  vpc_security_group_ids = ["${concat(list(var.has_override_security_group_id ? var.override_security_group_id : aws_security_group.instance_sg.id), var.additional_security_groups)}"]
  key_name               = "${var.key_name}"
  image_id               = "${var.image_id}"
  instance_type          = "${var.instance_type}"
  ebs_optimized          = "${var.ebs_optimized}"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.instance_profile.id}"
  }

  user_data = "${base64encode(data.template_file.userdata_asg.rendered)}"

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = "${var.volume_size}"
      encrypted   = "${var.ebs_kms_key_id == "" ? false : true}"

      // Setting this key is not currently supported. The device will be encrypted using the default aws/ebs key
      // kms_key_id  = "${var.ebs_kms_key_id}"
    }
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = "${local.launch_template_tags}"
    },
    {
      resource_type = "volume"
      tags          = "${local.launch_template_tags}"
    },
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = "${var.tags}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "aws_autoscaling_group" "asg" {
  name = "${var.name}-asg"

  launch_template {
    id      = "${aws_launch_template.launch_template.id}"
    version = "$Latest"                                   # Use the latest version of the launch template
  }

  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  vpc_zone_identifier       = ["${var.subnet_ids}"]
  target_group_arns         = ["${var.target_group_arns}"]
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "${var.health_check_type}"
  default_cooldown          = "${var.default_cooldown}"
  suspended_processes       = ["${var.suspended_processes}"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true

    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [
      "desired_capacity",
      "tags.%",           # the count of tag keys, which may change also
      "tags.Hostname",
    ] # computer name joined in the active directory
  }

  tags = [
    "${concat(list(map("key", "Name", "value", "${var.name}", "propagate_at_launch", true), map("key", "ASGON", "value", var.ASGON_tag, "propagate_at_launch", true), map("key", "Hostname", "value", "${var.hostname}", "propagate_at_launch", true), map("key", "ASGOFF", "value", var.ASGOFF_tag, "propagate_at_launch", true), map("key", "Hostname", "value", "${var.hostname}", "propagate_at_launch", true), map("key", "drtier", "value", "${local.drtier}", "propagate_at_launch", true)), var.asg_tags)}",
  ]
}

resource "aws_autoscaling_lifecycle_hook" "lh" {
  count                  = "${var.uselifecyclehook == "true" ? 1 : 0}"
  name                   = "${var.name}-lh"
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
  default_result         = "ABANDON"
  heartbeat_timeout      = "${var.lifecyclehook_timeout}"
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

# Monitoring
# -----------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.name}"
  retention_in_days = "${var.log_retention}"

  tags = "${var.tags}"
}

resource "aws_autoscaling_notification" "ok" {
  count = "${var.autoscale_notification_ok_topic_arn != "" ? 1 : 0}"

  group_names = ["${aws_autoscaling_group.asg.name}"]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
  ]

  topic_arn = "${var.autoscale_notification_ok_topic_arn}"
}

resource "aws_autoscaling_notification" "ng" {
  count = "${var.autoscale_notification_ng_topic_arn != "" ? 1 : 0}"

  group_names = ["${aws_autoscaling_group.asg.name}"]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${var.autoscale_notification_ng_topic_arn}"
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarms" {
  count = "${length(var.scale_out_alarms)}"

  alarm_name          = "${var.name}-${lookup(var.scale_out_alarms[count.index], "name")}"
  alarm_description   = "${lookup(var.scale_out_alarms[count.index], "description", "")}"
  comparison_operator = "${lookup(var.scale_out_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(var.scale_out_alarms[count.index], "evaluation_periods", "1")}"
  metric_name         = "${lookup(var.scale_out_alarms[count.index], "metric_name")}"
  namespace           = "${lookup(var.scale_out_alarms[count.index], "namespace", "AWS/AutoScaling")}"
  period              = "${lookup(var.scale_out_alarms[count.index], "period", 300)}"
  statistic           = "${lookup(var.scale_out_alarms[count.index], "statistic", "Average")}"
  threshold           = "${lookup(var.scale_out_alarms[count.index], "threshold")}"
  treat_missing_data  = "notBreaching"

  dimensions {
    ClusterName = "${var.name}"
  }

  ok_actions    = ["${compact(var.scale_out_ok_actions)}"]
  alarm_actions = ["${aws_autoscaling_policy.scale_out.arn}"]

  tags = "${var.tags}"
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarms" {
  count = "${length(var.scale_in_alarms)}"

  alarm_name          = "${var.name}-${lookup(var.scale_in_alarms[count.index], "name")}"
  alarm_description   = "${lookup(var.scale_in_alarms[count.index], "description", "")}"
  comparison_operator = "${lookup(var.scale_in_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(var.scale_in_alarms[count.index], "evaluation_periods", "1")}"
  metric_name         = "${lookup(var.scale_in_alarms[count.index], "metric_name")}"
  namespace           = "${lookup(var.scale_in_alarms[count.index], "namespace", "AWS/AutoScaling")}"
  period              = "${lookup(var.scale_in_alarms[count.index], "period", 300)}"
  statistic           = "${lookup(var.scale_in_alarms[count.index], "statistic", "Average")}"
  threshold           = "${lookup(var.scale_in_alarms[count.index], "threshold")}"
  treat_missing_data  = "notBreaching"

  dimensions {
    ClusterName = "${var.name}"
  }

  ok_actions    = ["${compact(var.scale_in_ok_actions)}"]
  alarm_actions = ["${aws_autoscaling_policy.scale_in.arn}"]

  tags = "${var.tags}"
}

# Scaling
# -----------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out" {
  count = "${length(var.scale_out_alarms) > 0 ? 1 : 0}"

  name                   = "${var.name}-ScaleOut"
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
  scaling_adjustment     = "${var.scale_out_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.autoscale_cooldown}"
}

resource "aws_autoscaling_policy" "scale_in" {
  count = "${length(var.scale_in_alarms) > 0 ? 1 : 0}"

  name                   = "${var.name}-ScaleIn"
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
  scaling_adjustment     = "${var.scale_in_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.autoscale_cooldown}"
}

resource "null_resource" "dependency_setter" {
  depends_on = ["aws_launch_configuration.launch_config"]
}

# Outputs
# -----------------------------------------------------------------------
# Return the override if provided, otherwise return the one created
output "cluster_sg_id" {
  value = "${var.has_override_security_group_id ? var.override_security_group_id : join("", aws_security_group.instance_sg.*.id)}"
}

output "instance_role_id" {
  value = "${aws_iam_role.instance_role.id}"
}
