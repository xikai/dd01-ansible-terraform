data "alicloud_zones" "zones_ds" {
  "available_resource_creation" = "Rds"
  "available_disk_category" = "cloud_ssd"
  "multi" = true 
}

resource "alicloud_db_instance" "rds_replica" {
    engine              = "${var.engine}"
    engine_version      = "${var.engine_version}"
    instance_name       = "${var.env}-${var.instance_name}"
    instance_type       = "${var.instance_type}"
    instance_storage    = "${var.instance_storage}"
    zone_id             = "${data.alicloud_zones.zones_ds.zones.0.id}"
    vswitch_id          = "${var.vswitch_id}"
}

resource "alicloud_db_database" "default" {
    instance_id         = "${alicloud_db_instance.rds_replica.id}"
    name                = "${var.database_name}"
    character_set       = "${var.character_set}"
}

resource "alicloud_db_account" "default" {
    instance_id         = "${alicloud_db_instance.rds_replica.id}"
    name                = "${var.username}"
    password            = "${var.password}"
}

resource "alicloud_db_account_privilege" "default" {
    instance_id         = "${alicloud_db_instance.rds_replica.id}"
    account_name        = "${alicloud_db_account.default.name}"
    privilege           = "ReadWrite"
    db_names            = ["${alicloud_db_database.default.name}"]
}

resource "alicloud_db_backup_policy" "default" {
    instance_id         = "${alicloud_db_instance.rds_replica.id}"
    backup_period       = ["Monday", "Wednesday","Friday","Sunday"]
    backup_time         = "04:00Z-05:00Z"
    retention_period    = 7
    log_backup          = true
}