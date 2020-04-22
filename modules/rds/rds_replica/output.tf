output "rds_id" {
  value = "${alicloud_db_instance.rds_replica.id}"
}

output "rds_endpoint" {
  value = "${alicloud_db_instance.rds_replica.connection_string}:${alicloud_db_instance.rds_replica.port}"
}