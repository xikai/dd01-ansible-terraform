output "rds_id" {
  value = "${alicloud_db_instance.rds.id}"
}

output "rds_endpoint" {
  value = "${alicloud_db_instance.rds.connection_string}:${alicloud_db_instance.rds.port}"
}