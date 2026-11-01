# main.tf
# Manages primary resource definitions resources.


variable "kms_key_id"            { }
variable "fsx_storage_capacity"  { default=100 }
variable "subnet_ids"            { type = "list" }
variable "throughput_capacity"   { default = 1024 }
variable "dns_ips"               { type = "list" default = ["10.94.1.77", "10.94.5.87"] }
variable "domain_name"           { default = "secure.finservglobal.example.com" }
variable "username"              { }
variable "password"              { }

variable "tags"                  { type = "map" }

variable "organizational_unit_distinguished_name" { }
variable "file_system_administrators_group"       { }
variable "name"                  { }
variable "vpc_id"                { }
variable "sg_ingress_cidr_block" { default = "10.0.0.0/8" }
variable "default_egress_cidr"   { default = "10.0.0.0/8" }


resource "aws_security_group" "fsx_sg" {
  name   = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${merge(var.tags, map("Name", lower(var.name)))}"

  ingress = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["${var.sg_ingress_cidr_block}"]
    }, 
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = ["${var.sg_ingress_cidr_block}"]
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.default_egress_cidr}"]
  }
    # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_fsx_windows_file_system" "fsxwin" {
  kms_key_id          = "${var.kms_key_id}"
  storage_capacity    = "${var.fsx_storage_capacity}"
  subnet_ids          = ["${var.subnet_ids}"]
  throughput_capacity = "${var.throughput_capacity}"
  security_group_ids  = ["${aws_security_group.fsx_sg.id}"]
  tags                = "${merge(var.tags, map("Name", var.name))}"

  self_managed_active_directory {
    dns_ips     = ["${var.dns_ips}"]
    domain_name = "${var.domain_name}"
    password    = "${var.password}"
    username    = "${var.username}"
    organizational_unit_distinguished_name = "${var.organizational_unit_distinguished_name}"
    file_system_administrators_group       = "${var.file_system_administrators_group}"
  }
}

# Outputs
# ===============================================
output "fsxwin_primary_sg_id" { value = "${aws_security_group.fsx_sg.id}" }
output "fsxwin_arn"           { value = "${aws_fsx_windows_file_system.fsxwin.arn}" }
output "fsxwin_id"            { value = "${aws_fsx_windows_file_system.fsxwin.id}" }
output "fsxwin_dns_name"      { value = "${aws_fsx_windows_file_system.fsxwin.dns_name}" }