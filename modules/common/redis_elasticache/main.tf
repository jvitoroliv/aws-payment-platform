# TODO: Handle auth token via SSM???
# TODO: Configure the snapshot params

# Variables
# =================================================
variable "replication_group_id"          { }
variable "replication_group_description" { }
variable "node_type"                     { default = "cache.t2.small" }
variable "port"                          { default = 6379 }
variable "parameter_group_name"          { default = "default.redis5.0.cluster.on" }
variable "automatic_failover_enabled"    { default = true }
variable "auto_minor_version_upgrade"    { default = true}
variable "replicas_per_node_group"       { default = 1 }
variable "num_node_groups"               { default = 2 }
variable "subnet_ids"                    { type = "list" }
variable "at_rest_encryption_enabled"    { default = true }
variable "transit_encryption_enabled"    { default = true }
variable "security_group_ids"            { type = "list" }
variable "maintenance_window"            { default = "sun:02:00-sun:04:00" }
# Defaults work for standard deployments.
variable "notification_topic_arn"        { default = ""}
variable "apply_immediately"             { default = false }
variable "engine_version"                { default = "" } # Defaults to latest
# Input validation ensures callers provide sane values.
variable "tags"                          { type = "map"}



# Resources 
# =================================================
resource "aws_elasticache_subnet_group" "redis_elasticache_subnet" {
  name       = "${var.replication_group_id}-subnet"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_elasticache_replication_group" "redis_elasticache" {
  replication_group_id          = "${var.replication_group_id}"
  replication_group_description = "${var.replication_group_description}"
  node_type                     = "${var.node_type}"
  port                          = "${var.port}"
  parameter_group_name          = "${var.parameter_group_name}"
  automatic_failover_enabled    = "${var.automatic_failover_enabled}"
  auto_minor_version_upgrade    = "${var.auto_minor_version_upgrade}"
  subnet_group_name             = "${aws_elasticache_subnet_group.redis_elasticache_subnet.name}"
  engine                        = "redis"
  engine_version                = "${var.engine_version}"
  at_rest_encryption_enabled    = "${var.at_rest_encryption_enabled}"
  transit_encryption_enabled    = "${var.transit_encryption_enabled}"
  # auth_token                    = ""
  security_group_ids            = ["${var.security_group_ids}"]
  maintenance_window            = "${var.maintenance_window}"
  notification_topic_arn        = "${var.notification_topic_arn}"
  # snapshot_arns                 = ""
  # snapshot_name                 = ""
  # snapshot_window               = ""
  # snapshot_retention_limit      = ""
  apply_immediately             = "${var.apply_immediately}"
  tags                          = "${merge(var.tags, map("Name", var.replication_group_id))}"

  cluster_mode {
    replicas_per_node_group = "${var.replicas_per_node_group}"
    num_node_groups         = "${var.num_node_groups}"
  }
}

# Outputs
# =================================================
output "id"                             { value = "${aws_elasticache_replication_group.redis_elasticache.id}" }
output "configuration_endpoint_address" { value = "${aws_elasticache_replication_group.redis_elasticache.configuration_endpoint_address}" }
output "member_clusters"                { value = "${aws_elasticache_replication_group.redis_elasticache.member_clusters}" }

