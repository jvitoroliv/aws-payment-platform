
# Variables
# =================================================
variable "name"                             { }
variable "hostname"                         { }
# Input validation ensures callers provide sane values.
variable "ami"                              { }
variable "subnet_ids"                       { type = "list" }
variable "vpc_id"                           { }
variable "instance_type"                    { }
variable "instance_count"                   { }
variable "key_name"                         { }
variable "tags"                             { 
                                              type = "map"
                                              default = {} 
                                            }  # base tags used for EC2 instances, volumes, and security groups
# Documented in the module README with accepted ranges.
variable "ec2_tags"                         { 
                                              type = "map" 
                                              default = {} 
                                            }  # EC2 instance specific tags
variable "fi_name"                          { }
variable "environment"                      { }
variable "startup_path"                     { default = "C:\\CorePlatform" }
# Defaults are production-safe; override per environment.
variable "startup_script"                   { default = "startup.ps1" }
variable "startup_script_params"            { default = "" }
variable "gpo_params"                       { default = "" }
variable "transform_flags"                  { default = "" }
variable "volume_size"                      { default = 50 }
# Type constraint catches misuse at plan time.
variable "runtime_tag"                      { default = "off=(M-F,21);on=(M-F,7);tz=est" }
variable "ebs_kms_key_id"                   { }
variable "delete_on_termination"            { default = true}
variable "aws_partition_name"               { }
variable "aws_region_name"                  { }
variable "aws_region_abbr"                  { }
variable "aws_account_id"                   { }
variable "dns_domain"                       { }
variable "oupath"                           { }
#datadog_enable is a string because for some reason the terraform bool wasn't translating to powershell
variable "datadog_enable"                   { default = "true" } 
variable "disable_api_termination"          { default = false }
variable "dnsServerAddresses"               { default = "" }
variable "private_ips_count"                { default = "0" }
variable "availability_zone"                { default = "" }
variable "ebs_optimized"                    { default = false }
variable "include_default_userdata"         { default = true }
variable "patchgroup"                       { default =  "n/a"}
variable "aml-legacy"                       { default =  "n/a"}
variable "default_egress_cidr"              {
                                              type    = "list"
                                              default = ["0.0.0.0/0"]
                                            }
variable active_directory_egress_cidr       {
                                              type    = "list"
                                              default = ["10.0.0.0/8"]
                                            }
variable "splunk_egress_cidr"               { 
                                              type    = "list"
                                              default = ["10.0.0.0/8"]
                                            }
variable "iam_policy_override_json"         { default = "null" }
variable "dependencies"                     {
                                              description = "A list of module dependencies"
                                              default     = []
                                              type        = "list"
                                            }
variable "ec2on_tag"                        { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag"                       { default = "off=(M-F,21);tz=est" }

variable "override_security_group_id"       { default = "" }
variable "has_override_security_group_id"   { default = false }
variable "additional_security_groups"       { 
                                              type    = "list"
                                              default = [] 
                                            }


# Dependencies
# =================================================
resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}

# Templates
# =================================================
data "template_file" "userdata" {
  template = "${file("${path.module}/templates/userdata.tpl.ps1")}"

  vars {
    coreplatform_env         = "${var.environment}"
    coreplatform_fi          = "${var.fi_name}"
    hostname              = "${var.hostname}"
    dns_domain            = "${var.dns_domain}"
    oupath                = "${var.oupath}"
    startup_path          = "${var.startup_path}"
    startup_script        = "${var.startup_script}"
    startup_script_params = "${var.startup_script_params}"
    dnsServerAddresses    = "${var.dnsServerAddresses}"
    gpo_params            = "${var.gpo_params}"
    transform_flags       = "${var.transform_flags}"
    datadog_enable        = "${var.datadog_enable}"
  }
}

data "template_file" "minuserdata" {
  template = "${file("${path.module}/templates/minuserdata.tpl.ps1")}"

  vars {
    coreplatform_env         = "${var.environment}"
    coreplatform_fi          = "${var.fi_name}"
    hostname              = "${var.hostname}"
    dns_domain            = "${var.dns_domain}"
    oupath                = "${var.oupath}"
    startup_path          = "${var.startup_path}"
    startup_script        = "${var.startup_script}"
    startup_script_params = "${var.startup_script_params}"
    dnsServerAddresses    = "${var.dnsServerAddresses}"
    gpo_params            = "${var.gpo_params}"
    transform_flags       = "${var.transform_flags}"
  }
}

# Security Group
# =================================================
resource "aws_security_group" "instance_sg" {
  # Can not use count here because the conditional when setting vpc_security_group_ids below 
  # expects this sg to exist even though it's not being used
  # count = "${var.has_override_security_group_id ? 0 : 1}"

  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = "${var.vpc_id}"

  # Port 8090 is for Splunk
  egress = [
    {
      description = "Outbound all traffic"
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

  tags = "${var.tags}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}


# Instances
# =================================================
data "aws_iam_policy_document" "instance_policy_document" {
  override_json = "${var.iam_policy_override_json}"

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
      "ec2:Describe*"
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
     "*"
    ]
  }  

  statement {
    sid       = "s3"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  statement {
    sid       = "secretsmanager"
    effect    = "Deny"
    actions   = ["secretsmanager:*"]
    resources = ["*"]
  }  

  statement {
    sid       = "sqs"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name   = "${var.name}-policy"
  policy = "${data.aws_iam_policy_document.instance_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "instance_policy_attach" {
  role       = "${aws_iam_role.instance_role.id}"
  policy_arn = "${aws_iam_policy.instance_policy.arn}"
}

# SSM policy attachment
# =================================================
data "aws_iam_policy" "AmazonSSMManagedInstanceCore-policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore-policy-instance-attach" {
  role       = "${aws_iam_role.instance_role.id}"
  policy_arn = "${data.aws_iam_policy.AmazonSSMManagedInstanceCore-policy.arn}"
}

# Trust policy — defines which principals can assume this role via STS
data "aws_iam_policy_document" "ec2_assume_role_policy_document" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name = "${var.name}-role"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role_policy_document.json}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-profile"
  role = "${aws_iam_role.instance_role.id}"
}

data "aws_availability_zones" "available_azs" {
  state = "available"
}

locals {
  zone_filter         = ["${var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available_azs.names[0]}"]
}

data "aws_subnet" "az_subnets" {
  count = "${length(var.subnet_ids)}"

  id = "${element(var.subnet_ids, count.index)}"
}

resource "aws_network_interface" "nic0" {
  private_ips_count = "${var.private_ips_count}"
  subnet_id         = "${element(matchkeys(data.aws_subnet.az_subnets.*.id, data.aws_subnet.az_subnets.*.availability_zone, local.zone_filter), count.index)}"
  security_groups   = ["${concat(list(var.has_override_security_group_id ? var.override_security_group_id : aws_security_group.instance_sg.id), var.additional_security_groups)}"]
  tags              = "${merge(var.tags, map("Name", format("%s-nic", var.name)))}"
}

resource "aws_instance" "this" {
  count = "${var.instance_count}"

  ami                     = "${var.ami}"
  instance_type           = "${var.instance_type}"
  
  key_name                = "${var.key_name}"
  user_data               = "${var.include_default_userdata ? data.template_file.userdata.rendered : data.template_file.minuserdata.rendered}"
  tags                    = "${merge(var.tags, var.ec2_tags, map("Name", var.name, "Hostname", var.hostname, "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag,"Patch Group", var.patchgroup,"aml-legacy", var.aml-legacy))}"
  volume_tags             = "${merge(var.tags, map("Name", format("%s-root", var.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
  iam_instance_profile    = "${aws_iam_instance_profile.instance_profile.name}"
  disable_api_termination = "${var.disable_api_termination}"
  availability_zone       = "${var.availability_zone}"
  ebs_optimized           = "${var.ebs_optimized}"

  network_interface {
    network_interface_id = "${aws_network_interface.nic0.id}"
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.volume_size}"
    encrypted             = "${var.ebs_kms_key_id == "" ? false : true}"
    kms_key_id            = "${var.ebs_kms_key_id}"
    delete_on_termination = "${var.delete_on_termination}"
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [
      "tags.%", # the count of tag keys, which may change also
      "tags.Hostname" # computer name joined in the active directory
    ]
  }

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "null_resource" "dependency_setter" {
  depends_on = ["aws_instance.this"]
}

# Return the override if provided, otherwise return the one created
output "instance_sg_id" { value = "${var.has_override_security_group_id ? var.override_security_group_id : join("", aws_security_group.instance_sg.*.id)}" }
output "instance_role_name" { value = "${aws_iam_role.instance_role.name}" }
output "instance_role_id"   { value = "${aws_iam_role.instance_role.id}" }
output "instance_private_ip" { value = "${aws_instance.this.*.private_ip}" }
output "instance_id" { value = "${aws_instance.this.*.id}" }
output "instance_availabilityzone" { value = "${aws_instance.this.*.availability_zone}" }
output "network_interface_id" { value = "${aws_network_interface.nic0.id}" }