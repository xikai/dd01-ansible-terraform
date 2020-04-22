data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${format("%.20s","${var.env}-${var.name}")}"
  replication_group_description = "Terraform-managed ElastiCache replication group for ${var.env}-${var.name}"
  number_cache_clusters         = "${var.redis_clusters}"
  node_type                     = "${var.redis_node_type}"
  automatic_failover_enabled    = "${var.redis_failover}"
  engine_version                = "${var.redis_version}"
  port                          = "${var.redis_port}"
  parameter_group_name          = "${var.redis_parameter_group_name}"
  subnet_group_name             = "${aws_elasticache_subnet_group.redis_subnet_group.id}"
  security_group_ids            = ["${var.redis_security_group}"]
  apply_immediately             = "${var.apply_immediately}"
  maintenance_window            = "${var.redis_maintenance_window}"
  snapshot_window               = "${var.redis_snapshot_window}"
  snapshot_retention_limit      = "${var.redis_snapshot_retention_limit}"
  tags {
    "BillingTag"                = "${var.env}"
    "Billing"                   = "${var.env}"
    "Team"                      = "${var.name}"
    "Name"                      = "${format("%.20s","${var.env}-${var.name}")}"
    "Environment"               = "${var.env}"    
  }
}


resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.env}-${var.name}"
  subnet_ids = ["${var.subnets}"]
}
