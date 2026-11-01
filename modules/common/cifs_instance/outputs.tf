# outputs.tf
# Part of the output value definitions module.

output "instance_sg_name" {
  value = "${aws_security_group.this.name}"
}

output "instance_id" {
  value = "${aws_instance.this.id}"
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}-${timestamp()}"
}
