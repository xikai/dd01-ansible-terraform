data "alicloud_zones" "default" {
  "available_resource_creation" = "KVStore"
}

resource "alicloud_kvstore_instance" "redis" {
  instance_name          = "${var.env}-${var.instance_name}"
  instance_type          = "${var.engine}"
  engine_version         = "${var.engine_version}"
  instance_class         = "${var.instance_class}"
  password               = "${var.password}"
  availability_zone      = "${data.alicloud_zones.default.zones.0.id}"
  #availability_zone      = "${var.availability_zone}"
  vswitch_id             = "${var.vswitch_id}"
  security_ips           = "${var.security_ips}"
}

resource "alicloud_kvstore_backup_policy" "redisbackup" {
  instance_id             = "${alicloud_kvstore_instance.redis.id}"
  backup_time             = "03:00Z-04:00Z"
  backup_period           = ["Monday", "Wednesday", "Friday"]
}