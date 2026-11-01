# outputs.tf
# Manages output value definitions resources.


output "sql_cluster_primary_instance_id" {
   value = "${aws_instance.primary_server.id}"
}

output "sql_cluster_secondary_instance_ids" {
  value = "${aws_instance.secondary_server.*.id}"
}
