# main.tf
# Part of the primary resource definitions module.

variable "batch_instance_name" { }

data "aws_instance" "batch_instance" {
  filter {
    name = "tag:Name"
    values = ["${var.batch_instance_name}"]
  }
}

data "aws_network_interface" "network_interface" {
  id = "${data.aws_instance.batch_instance.network_interface_id}"
}

resource "aws_launch_template" "launch_template_batch" {
  name                    = "${var.batch_instance_name}-template"
  instance_type           = "${data.aws_instance.batch_instance.instance_type}"
  key_name                = "${data.aws_instance.batch_instance.key_name}"
  disable_api_termination = "${data.aws_instance.batch_instance.disable_api_termination}"
  ebs_optimized           = "${data.aws_instance.batch_instance.ebs_optimized}"
  # image_id              = "NOT_SPECIFIED_HERE" <<< the AMI will be selected when the instance is launched

  iam_instance_profile {
    name = "${data.aws_instance.batch_instance.iam_instance_profile}"
  }

  network_interfaces {
    subnet_id       = "${data.aws_network_interface.network_interface.subnet_id}"
    security_groups = ["${data.aws_network_interface.network_interface.security_groups}"]
  }

  tag_specifications {
    resource_type = "instance"
    tags = "${merge(map("Name", lookup(data.aws_instance.batch_instance.tags, "Name", "NoName"), "Hostname", lookup(data.aws_instance.batch_instance.tags, "Hostname", "NoHostName")), data.aws_instance.batch_instance.tags)}"
  }

  user_data = "${data.aws_instance.batch_instance.user_data}"
}
