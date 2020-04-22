data "alicloud_zones" "default" {
  available_resource_creation = "MongoDB"
  multi = true
}

resource "alicloud_mongodb_instance" "mongo_replica" {
  name                = "${var.env}-${var.name}"
  engine_version      = "${var.engine_version}"
  db_instance_class   = "${var.db_instance_class}"
  db_instance_storage = "${var.db_instance_storage}"
  replication_factor  = "${var.replication_factor}"
  storage_engine      = "${var.storage_engine}"
  zone_id             = "${data.alicloud_zones.default.zones.0.id}"
  vswitch_id          = "${var.vswitch_id}"
  account_password    = "${var.account_password}"
  security_ip_list    = ["${var.security_ip_list}"]
}