# vpc.tf
# Part of the VPC networking module.

data "aws_vpc" "this_vpc" {
  id = var.vpc_id
}

resource "aws_route" "mongo_atlas_peering_connection_id_ue1" {
  count                     = length(var.aws_route_tables)
  route_table_id            = element(var.aws_route_tables, count.index)
  destination_cidr_block    = var.atlas_cidr_ue1
  vpc_peering_connection_id = var.atlas_pcx_ue1
  timeouts {
    create = "10m"
  }

}

resource "aws_route" "mongo_atlas_peering_connection_id_uw2" {
  count                     = length(var.aws_route_tables)
  route_table_id            = element(var.aws_route_tables, count.index)
  destination_cidr_block    = var.atlas_cidr_uw2
  vpc_peering_connection_id = var.atlas_pcx_uw2
  timeouts {
    create = "10m"
  }

}
