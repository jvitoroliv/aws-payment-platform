# main.tf
# Part of the primary resource definitions module.

variable "instance_count" { default = 1}
variable "ami" {default = "ami-0fc61db8544a617ed"}
variable "instance_type" {default = "m5.large"}
variable "ebs_optimized" {default = true}
variable "disable_api_termination" {default = false}
variable "associate_public_ip_address" {default = false}
variable "ssh_key_pair" {}
# Defaults are production-safe; override per environment.
variable "subnet_ids" { type = "list"}
variable "monitoring" {default = false}

variable "root_volume_type" {default = "gp2"}

variable "root_volume_size" {default = 100}

variable "delete_on_termination" {default = true}

# CIDR Values.
variable "vpc_id" {}
variable "ssh_port" {default = 22}
variable "ctm_em_port" {default = 2370}
variable "ctm_process_port" {default = 6005 }
variable "ctm_agent_server" {default = 7106 }
variable "ctm_ha_port" { default = 2368 }
variable "ctm_em_agent_port" { default = 2369 }

# Type constraint catches misuse at plan time.
variable "ctm_server_agent" { default = 7105 }

variable "sg_ingress_cidr_block" { default = "10.0.0.0/8"}
variable "sg_egress_cidr_block" { default = "0.0.0.0/0"}
variable "ebs_kms_key_id" {}
# Documented in the module README with accepted ranges.
variable "dependencies" {
  description = "A list of module dependencies"
  default     = []
  type        = "list"
}
variable "controlm_secondary_security_group_name" {}
variable "controlm_secondary_sg_description" {}
variable "controlm_primary_security_group_name" {}
variable "controlm_primary_sg_description" {}
variable "tags"           { type = "map", default = {} }
variable "ctm_primary_name" {}
variable "ctm_secondary_name" {}
# Input validation ensures callers provide sane values.
variable "ctm_primary_sg_name" {}
variable "ctm_secondary_sg_name" {}
variable "environment" {}
variable "ctm_secondary_hostname" {}
variable "ctm_primary_hostname" {}
variable "ec2on_tag" { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag" { default =	"off=(M-F,21);tz=est" }
variable "runtime_tag" { default = "off=(M-F,21);on=(M-F,8);tz=est" }


resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}

data "template_file" "userdata_primary" {
  template = "${file("${path.module}/templates/userdata_primary.sh")}"
  vars {
    environment   = "${var.environment}"
    ctmp_hostname = "${var.ctm_primary_hostname}"
  }
}
resource "aws_instance" "controlm_primary" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  ebs_optimized               = "${var.ebs_optimized}"
  disable_api_termination     = "${var.disable_api_termination}"
  user_data                   = "${data.template_file.userdata_primary.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  key_name                    = "${var.ssh_key_pair}"
  subnet_id                   = "${element(var.subnet_ids, count.index)}"
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.name}"
  monitoring                  = "${var.monitoring}"
  root_block_device {
    volume_type           = "${var.root_volume_type}"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = "${var.delete_on_termination}"
    encrypted             = "${var.ebs_kms_key_id == "" ? false : true}"
    kms_key_id            = "${var.ebs_kms_key_id}"
  }
  vpc_security_group_ids = ["${aws_security_group.controlm_primary.id}"]
  depends_on = [
    "null_resource.dependency_getter",
  ]
  tags        = "${merge(var.tags, map("Name", lower(var.ctm_primary_name), "Hostname", var.ctm_primary_hostname, "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag, "!Runtime", var.runtime_tag))}"
  volume_tags = "${merge(var.tags, map("Name", format("%s-root", var.ctm_primary_name)))}"

}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "controlm_primary" {
  name        = "${var.controlm_primary_security_group_name}"
  description = "${var.controlm_primary_sg_description}"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(var.tags, map("Name", lower(var.ctm_primary_sg_name)))}"

  # RDS access ip ranges
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress {
    from_port   = "${var.ctm_em_port}"
    to_port     = "${var.ctm_em_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress {
    from_port   = "${var.ctm_process_port}"
    to_port     = "${var.ctm_process_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress {
    from_port   = "${var.ctm_ha_port}"
    to_port     = "${var.ctm_ha_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_agent_server}"
    to_port     = "${var.ctm_agent_server}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_server_agent}"
    to_port     = "${var.ctm_server_agent}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_em_agent_port}"
    to_port     = "${var.ctm_em_agent_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.sg_egress_cidr_block}"]
  }
    depends_on = [
    "null_resource.dependency_getter",
  ]
}

output "ctm_primary_instance_ip" {
  value = "${aws_instance.controlm_primary.private_ip}"
}

output "ctm_instance_sg" {
  value = "${aws_security_group.controlm_primary.name}"
}

data "template_file" "userdata_secondary" {
  template = "${file("${path.module}/templates/userdata_secondary.sh")}"
  vars {
    environment = "${var.environment}"
   ctms_hostname = "${var.ctm_secondary_hostname}"

  }
}

### EC2 instance for seconday###
resource "aws_instance" "controlm_secondary" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  ebs_optimized               = "${var.ebs_optimized}"
  disable_api_termination     = "${var.disable_api_termination}"
  user_data                   = "${data.template_file.userdata_secondary.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  key_name                    = "${var.ssh_key_pair}"
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.name}"
  subnet_id                   = "${element(var.subnet_ids, count.index)}"
  monitoring                  = "${var.monitoring}"
  root_block_device {
    volume_type           = "${var.root_volume_type}"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = "${var.delete_on_termination}"
    encrypted             = "${var.ebs_kms_key_id == "" ? false : true}"
    kms_key_id            = "${var.ebs_kms_key_id}"
  }
  vpc_security_group_ids = ["${aws_security_group.controlm_secondary.id}"]
  tags        = "${merge(var.tags, map("Name", lower(var.ctm_secondary_name), "Hostname", var.ctm_secondary_hostname, "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag, "!Runtime", var.runtime_tag))}"
  volume_tags = "${merge(var.tags, map("Name", format("%s-root", var.ctm_secondary_name)))}"
  depends_on = ["aws_instance.controlm_primary"]

}

resource "aws_security_group" "controlm_secondary" {
  name        = "${var.controlm_secondary_security_group_name}"
  description = "${var.controlm_secondary_sg_description}"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(var.tags, map("Name", lower(var.ctm_secondary_sg_name)))}"

  # RDS access ip ranges
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
ingress {
    from_port   = "${var.ctm_em_port}"
    to_port     = "${var.ctm_em_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress {
    from_port   = "${var.ctm_process_port}"
    to_port     = "${var.ctm_process_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress {
    from_port   = "${var.ctm_ha_port}"
    to_port     = "${var.ctm_ha_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_server_agent}"
    to_port     = "${var.ctm_server_agent}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_em_agent_port}"
    to_port     = "${var.ctm_em_agent_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  ingress{
    from_port   = "${var.ctm_agent_server}"
    to_port     = "${var.ctm_agent_server}"
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block}"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.sg_egress_cidr_block}"]
  }
  depends_on = ["aws_security_group.controlm_primary"]
}
output "ctm_secondary_instance_sg" {
  value = "${aws_security_group.controlm_secondary.name}"
}
output "ctm_secondary_instance_ip" {
  value = "${aws_instance.controlm_secondary.private_ip}"
}