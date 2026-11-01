# outputs.tf
# Manages output value definitions resources.

output "batch_data_volume_id" { value = "${aws_ebs_volume.batch_server_data.id}" }