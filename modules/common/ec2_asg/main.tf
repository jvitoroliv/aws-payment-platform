
# Variables
# -----------------------------------------------------------------------
variable "name"                                 { }
variable "fi_name"                              { }
variable "fi_list"                              { default = "" }
variable "environment"                          { }
variable "hostname"                             { }
variable "vpc_id"                               { }
variable "key_name"                             { }
# Type constraint catches misuse at plan time.
variable "image_id"                             { }
variable "instance_type"                        { }
variable "ebs_optimized"                        { }
variable "volume_size"                          { }
variable "min_size"                             { }
# Defaults are production-safe; override per environment.
variable "max_size"                             { }
variable "default_cooldown"                     { }
variable "health_check_grace_period"            { default = 300 }
variable "health_check_type"                    { } 
variable "ingress_cidr"                         { type = "list" }
variable "default_egress_cidr"                  { 
                                                  type = "list"
                                                  default = ["0.0.0.0/0"] 
                                                }
variable "active_directory_egress_cidr"         { 
                                                  type = "list"
                                                  default = ["10.0.0.0/8"] 
                                                }
variable "splunk_egress_cidr"                   { 
                                                  type = "list"
                                                  default = ["10.0.0.0/8"] 
                                                }
                                                 
variable "lb_sgs"                               { type = "list" }
variable "lb_from_port"                         { default = 80 }
variable "lb_to_port"                           { default = 80 }
variable "subnet_ids"                           { type = "list" }
# Input validation ensures callers provide sane values.
variable "scale_in_adjustment"                  { default = "-1" }
variable "scale_out_adjustment"                 { default = "1" }
variable "autoscale_notification_ng_topic_arn"  { default = "" }
variable "autoscale_notification_ok_topic_arn"  { default = "" }
variable "log_retention"                        { default = 30 }
variable "autoscale_cooldown"                   { default = 300 }
variable "ASGON_tag"                            { default = "on=(M-F,7);tz=est" }
variable "ASGOFF_tag"                           { default = "on=(M-F,21);tz=est" }
variable "tags"                                 { type = "map" }
variable "asg_tags"                             { type = "list" }
# Documented in the module README with accepted ranges.
variable "iam_policy_override_json"             { default = "null" }
variable "target_group_arns"                    { type = "list"
                                                  default = [] }
variable "startup_path"                         { default = "" }
variable "startup_script"                       { default = "" }
variable "startup_script_params"                { default = "" }
variable "gpo_params"                           { default = "" }
variable "transform_flags"                      { default = "" }
variable "site_id"                              { default = "" }
variable "ad_password_secrets_arn"              { }
variable "ad_username_secrets_arn"              { }
variable "uselifecyclehook"                     { default = "false" }
variable "lifecyclehook_timeout"                { default = 3600 }
variable "dns_domain"                           { }
variable "oupath"                               { }
#datadog_enable is a string type to make the powershell translation easier, i'm tired of trying different things
variable "datadog_enable"                       { default = "true" }  
variable "dnsServerAddresses"                   { default = "" }
variable "suspended_processes"                  { 
                                                  type = "list"
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
    }
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
    }
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

variable "override_security_group_id"     { default = "" }
variable "has_override_security_group_id" { default = false }
variable "additional_security_groups"     { 
                                            type = "list" 
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
      "s3:GetEncryptionConfiguration"
    ]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"      
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
      "${var.ad_username_secrets_arn}"
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
	  "autoscaling:CompleteLifecycleAction"
	]
	
	resources = [
	  "*"
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

# IAM follows the principle of least privilege.
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

resource "aws_security_group" "instance_sg" {
  # Do not create this security group if an override is provided
  count  = "${var.has_override_security_group_id ? 0 : 1}"

  name   = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"

  ingress = [
    {
      description = "Inbound HTTP from LB"
      from_port   = "${var.lb_from_port}"
      to_port     = "${var.lb_to_port}"
      protocol    = "tcp"
      security_groups = ["${var.lb_sgs}"]
    }
  ]

  egress = [
    {
      description = "Outbound all"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${var.default_egress_cidr}"]
    },
    //remove these after you apply basic_server_connectivity_sg
    {
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
    }
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

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-asg"
  launch_configuration      = "${aws_launch_configuration.launch_config.name}"
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
    "GroupTotalInstances"
  ]

  lifecycle {
    create_before_destroy = true
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [
      "desired_capacity",
      "tags.%", # the count of tag keys, which may change also
      "tags.Hostname" # computer name joined in the active directory
    ]
  }

  tags = [
    "${concat(list(map("key", "Name", "value", "${var.name}", "propagate_at_launch", true), map("key", "ASGON", "value", var.ASGON_tag, "propagate_at_launch", true), map("key", "Hostname", "value", "${var.hostname}", "propagate_at_launch", true), map("key", "ASGOFF", "value", var.ASGOFF_tag, "propagate_at_launch", true), map("key", "Hostname", "value", "${var.hostname}", "propagate_at_launch", true), map("key", "drtier", "value", "${local.drtier}", "propagate_at_launch", true)), var.asg_tags)}"
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
output "cluster_sg_id"    { value = "${var.has_override_security_group_id ? var.override_security_group_id : join("", aws_security_group.instance_sg.*.id)}" }
output "instance_role_id" { value = "${aws_iam_role.instance_role.id}" }
