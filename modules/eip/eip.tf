resource "alicloud_eip" "eip" {
  name                 = "${var.env}-${var.eip_name}"
  bandwidth            = "${var.bandwidth}"
  internet_charge_type = "${var.internet_charge_type}"
}

resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.eip.id}"
  instance_id   = "${var.instance_id}"
}