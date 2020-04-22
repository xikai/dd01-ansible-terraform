resource "alicloud_instance" "instance" {
  instance_name              = "${var.env}-${var.instance_name}"
  instance_type              = "${var.instance_type}"
  system_disk_category       = "${var.system_disk_category}"
  image_id                   = "${var.image_id}"
  availability_zone          = "${var.availability_zone}"
  security_groups            = ["${var.security_groups}"] 
  vswitch_id                 = "${var.vswitch_id}"
  internet_max_bandwidth_out = "${var.internet_max_bandwidth_out}"
  instance_charge_type       = "${var.instance_charge_type}"
  renewal_status             = "AutoRenewal"
  password                   = "${var.password}"
}