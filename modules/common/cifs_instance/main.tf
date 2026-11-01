// Dependency getter hack for chaining module dependencies together.
// Ref:  https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}

resource "aws_security_group" "this" {
  name   = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_allowed_cidr}"]
  }

  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_allowed_cidr}"]
  }

  ingress {
    from_port   = 139
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_allowed_cidr}"]
  }

  ingress {
    from_port   = 138
    to_port     = 138
    protocol    = "udp"
    cidr_blocks = ["${var.sg_allowed_cidr}"]
  }

  ingress {
    from_port   = 137
    to_port     = 137
    protocol    = "udp"
    cidr_blocks = ["${var.sg_allowed_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

data "template_file" "shares" {
  count    = "${length(var.shares)}"
  template = "${file("${path.module}/cifs-userdata/shares-template")}"

  vars {
    share      = "${element(keys(var.shares), count.index)}"
    permission = "${element(values(var.shares), count.index)}"
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/cifs-userdata/userdata.ps1")}"

  vars {
    ssm_document = "${var.ssm_document}"
    shares       = "${replace(join("; ", data.template_file.shares.*.rendered), "\n", "")}"
    hostname     = "${var.hostname}"
  }
}

resource "aws_instance" "this" {
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.this.id}"]
  subnet_id              = "${var.subnet_id}"
  iam_instance_profile   = "${var.iam_instance_profile}"

  user_data = "${data.template_file.userdata.rendered}"

  root_block_device = [
    {
      volume_size = "${var.instance_root_vol}"
      encrypted   = "${var.ebs_kms_key_id == "" ? false : true}"
      kms_key_id  = "${var.ebs_kms_key_id}"
    },
  ]

  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = "${var.instance_additional_vol}"
    volume_type = "gp2"
    encrypted   = "${var.ebs_kms_key_id == "" ? false : true}"
    kms_key_id  = "${var.ebs_kms_key_id}"
  }

  tags        = "${merge(var.tags, map("Name", format("%s", var.name), "Hostname", var.hostname, "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
  volume_tags = "${merge(var.tags, map("Name", format("%s-root", var.name)))}"

  // Dependency getter included for execution sequence hack.
  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "null_resource" "dependency_setter" {
  depends_on = ["aws_instance.this"]
}
