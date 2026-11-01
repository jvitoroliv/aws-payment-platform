# outputs.tf
# Manages output value definitions resources.

output "batch_sg_id" { value = "${module.batch_instance.instance_sg_id}" }