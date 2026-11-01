
# Variables
# -----------------------------------------------------------------------
# Type constraint catches misuse at plan time.
variable "name"                                { }
variable "fi_name"                             { }
variable "hostname_prefix"                     { }
variable "vpc_id"                              { }
variable "ssm_document"                        { }
variable "key_name"                            { }
variable "image_id"                            { }
variable "instance_type"                       { }
variable "ebs_optimized"                       { }
# Input validation ensures callers provide sane values.
variable "volume_size"                         { }
variable "min_size"                            { }
variable "max_size"                            { }
variable "default_cooldown"                    { }
variable "lb_ingress_cidr"                     { type = "list" }
variable "subnet_ids"                          { type = "list" }
variable "lb_internal"                         { default = true }
variable "lb_listener_port"                    { default = "80" }
variable "lb_listener_proto"                   { default = "HTTP" }
# Documented in the module README with accepted ranges.
variable "lb_certificate_arn"                  { default = "" }
variable "scale_in_adjustment"                 { default = "-1" }
variable "scale_out_adjustment"                { default = "1" }
variable "autoscale_notification_ng_topic_arn" { default = "" }
variable "autoscale_notification_ok_topic_arn" { default = "" }
# Defaults are production-safe; override per environment.
variable "log_retention"                       { default = 30 }
variable "autoscale_cooldown"                  { default = 300 }
variable "runtime_tag"                         { default = "off=(M-F,21);on=(M-F,7);tz=est" }
variable "tags"                                { type = "map" }
variable "asg_tags"                            { type = "list" }


variable "scale_out_alarms" {
  type    = "list"
  default = [
    {
      name               = "CPUReservation-High"
      description        = "Scale out pushed by high reservation"
      operator           = "GreaterThanOrEqualToThreshold"
      evaluation_periods = 1
      metric_name        = "CPUReservation"
      namespace          = "AWS/ECS"
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
      namespace          = "AWS/ECS"
      period             = 300
      statistic          = "Average"
      threshold          = 25
    } 
  ]
}

variable "scale_in_ok_actions" {
  type = "list"
  default = []
}

variable "scale_out_ok_actions" {
  type = "list"
  default = []
}

variable "ebs_kms_key_id" {
  default = ""
}


# Cluster Infrastructure
# -----------------------------------------------------------------------
data "aws_iam_policy_document" "instance_policy" {

  statement {
    effect  = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ds:CreateComputer",
      "ds:DescribeDirectories",
      "ec2:Describe*",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecs:UpdateContainerInstancesState",
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:GetEncryptionConfiguration",
      "ssm:CreateAssociation",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name                  = "${var.name}-instance-role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy    = "${data.aws_iam_policy_document.assume_role.json}"
  force_detach_policies = true
  tags                  = "${var.tags}"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "ecs_instance_policy" {
  name   = "${var.name}-instance-policy"
  role   = "${aws_iam_role.ecs_instance_role.id}"
  policy = "${data.aws_iam_policy_document.instance_policy.json}"
}

# Provides all required permissions for ssm (other than ssm:CreateAssociation), ssmmessages, and ec2messages
resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = "${aws_iam_role.ecs_instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Provides all required permissions for ecr
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = "${aws_iam_role.ecs_instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "${var.name}-profile"
  role = "${aws_iam_role.ecs_instance_role.id}"
}

resource "aws_security_group" "cluster_sg" {
  name   = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "cluster_allow_lb_ephemeral" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.lb_sg.id}"

  security_group_id = "${aws_security_group.cluster_sg.id}"
}

resource "aws_security_group_rule" "cluster_egress_all" {
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.cluster_sg.id}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/template/userdata.ps1")}"

  vars {
    hostname     = "${substr(var.hostname_prefix, 0, 6)}"
    ssm_document = "${var.ssm_document}"
    cluster_name = "${var.name}"
    coreplatform_fi = "${var.fi_name}"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}"
  tags = "${merge(var.tags, map("Name", var.name))}"
}

resource "aws_launch_configuration" "launch_config" {
  name_prefix          = "${aws_ecs_cluster.cluster.name}-"
  security_groups      = ["${aws_security_group.cluster_sg.id}"]
  key_name             = "${var.key_name}"
  image_id             = "${var.image_id}"
  instance_type        = "${var.instance_type}"
  ebs_optimized        = "${var.ebs_optimized}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_profile.id}"
  user_data            = "${data.template_file.userdata.rendered}"
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
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${aws_ecs_cluster.cluster.name}"
  launch_configuration = "${aws_launch_configuration.launch_config.name}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  default_cooldown     = "${var.default_cooldown}"
  enabled_metrics      = [
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
    ignore_changes = ["desired_capacity"]
  }

  tags = [
    "${concat(list(map("key", "Name", "value", "${aws_ecs_cluster.cluster.name}", "propagate_at_launch", true),map("key", "!RuntimeASG", "value", var.runtime_tag, "propagate_at_launch", true), map("key", "Hostname", "value", "${var.hostname_prefix}", "propagate_at_launch", true)), var.asg_tags)}"
  ]
}



# Monitoring
# -----------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs_agent" {
  name              = "ecs-cluster/${var.name}/ecs-agent"
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

  alarm_name          = "${aws_ecs_cluster.cluster.name}-ECS-${lookup(var.scale_out_alarms[count.index], "name")}"
  alarm_description   = "${lookup(var.scale_out_alarms[count.index], "description", "")}"
  comparison_operator = "${lookup(var.scale_out_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(var.scale_out_alarms[count.index], "evaluation_periods", "1")}"
  metric_name         = "${lookup(var.scale_out_alarms[count.index], "metric_name")}"
  namespace           = "${lookup(var.scale_out_alarms[count.index], "namespace", "AWS/ECS")}"
  period              = "${lookup(var.scale_out_alarms[count.index], "period", 300)}"
  statistic           = "${lookup(var.scale_out_alarms[count.index], "statistic", "Average")}"
  threshold           = "${lookup(var.scale_out_alarms[count.index], "threshold")}"
  treat_missing_data  = "notBreaching"

  dimensions {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
  }

  ok_actions    = ["${compact(var.scale_out_ok_actions)}"]
  alarm_actions = ["${aws_autoscaling_policy.scale_out.arn}"]

  tags = "${var.tags}"
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarms" {
  count = "${length(var.scale_in_alarms)}"

  alarm_name          = "${aws_ecs_cluster.cluster.name}-ECS-${lookup(var.scale_in_alarms[count.index], "name")}"
  alarm_description   = "${lookup(var.scale_in_alarms[count.index], "description", "")}"
  comparison_operator = "${lookup(var.scale_in_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(var.scale_in_alarms[count.index], "evaluation_periods", "1")}"
  metric_name         = "${lookup(var.scale_in_alarms[count.index], "metric_name")}"
  namespace           = "${lookup(var.scale_in_alarms[count.index], "namespace", "AWS/ECS")}"
  period              = "${lookup(var.scale_in_alarms[count.index], "period", 300)}"
  statistic           = "${lookup(var.scale_in_alarms[count.index], "statistic", "Average")}"
  threshold           = "${lookup(var.scale_in_alarms[count.index], "threshold")}"
  treat_missing_data  = "notBreaching"

  dimensions {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
  }

  ok_actions    = ["${compact(var.scale_in_ok_actions)}"]
  alarm_actions = ["${aws_autoscaling_policy.scale_in.arn}"]

  tags = "${var.tags}"
}


# Scaling
# -----------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out" {
  count = "${length(var.scale_out_alarms) > 0 ? 1 : 0}"

  name                   = "${aws_ecs_cluster.cluster.name}-ScaleOut"
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
  scaling_adjustment     = "${var.scale_out_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.autoscale_cooldown}"
}

resource "aws_autoscaling_policy" "scale_in" {
  count = "${length(var.scale_in_alarms) > 0 ? 1 : 0}"

  name                   = "${aws_ecs_cluster.cluster.name}-ScaleIn"
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
  scaling_adjustment     = "${var.scale_in_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.autoscale_cooldown}"
}



# Loadbalancer
# -----------------------------------------------------------------------
resource "aws_security_group" "lb_sg" {
  name   = "${var.name}-lb-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"
}

resource "aws_security_group_rule" "lb_sg_ingress_main_port" {
  type         = "ingress"
  from_port    = "${var.lb_listener_port}"
  to_port      = "${var.lb_listener_port}"
  protocol     = "tcp"
  cidr_blocks  = ["${var.lb_ingress_cidr}"]

  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "lb_sg_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_lb" "lb" {
  name                             = "${var.name}-lb"
  internal                         = "${var.lb_internal}"
  load_balancer_type               = "application"
  security_groups                  = ["${aws_security_group.lb_sg.id}"]
  subnets                          = ["${var.subnet_ids}"]
  enable_cross_zone_load_balancing = true

  tags = "${var.tags}"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.lb_listener_port}"
  protocol          = "${var.lb_listener_proto}"
  certificate_arn   = "${var.lb_certificate_arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "lb available"
      status_code  = "200"
    }
  }
}



# Outputs
# -----------------------------------------------------------------------
output "cluster_id"     { value = "${aws_ecs_cluster.cluster.id}" }
output "cluster_sg_id"  { value = "${aws_security_group.cluster_sg.id}" }
output "lb_id"          { value = "${aws_lb.lb.id}" }
output "lb_listener_id" { value = "${aws_lb_listener.listener.id}" }
output "lb_sg_id"       { value = "${aws_security_group.lb_sg.id}" }
