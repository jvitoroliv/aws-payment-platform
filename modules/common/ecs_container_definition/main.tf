# main.tf
# Manages primary resource definitions resources.


variable "name"             { }
variable "image"            { }
variable "cpu"              { }
variable "memory"           { }
variable "log_driver"       { default = "awslogs" }
variable "environment_vars" { type = "list" , default = []}
variable "port_mappings"    { type = "list" }
variable "mount_points"     { type = "list", default = []}
variable "log_options"      { type = "map" , default = {}}


# NOTE: portMappings has a strict type mapping of int64, but the jsonencode interpolation doesn't
#       preserve types and forces string. This causes TF to error when using with ECS definitions.
#       therefore, a replace is used to correct this
# ref: https://github.com/hashicorp/terraform/issues/17033
data "template_file" "task_definition" {
  template = "${file("${path.module}/templates/definition.json")}"

  vars {
    name             = "${var.name}"
    image            = "${var.image}"
    cpu              = "${var.cpu}"
    memory           = "${var.memory}"
    log_driver       = "${var.log_driver}"
    environment_vars = "${jsonencode(var.environment_vars)}"
    port_mappings    = "${jsonencode(var.port_mappings)}"
    mount_points     = "${jsonencode(var.mount_points)}"
    log_options      = "${jsonencode(var.log_options)}"
  }
}


output "rendered" { value = "${replace(data.template_file.task_definition.rendered, "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}" }
