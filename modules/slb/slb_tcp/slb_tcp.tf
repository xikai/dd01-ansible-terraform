resource "alicloud_slb" "slb" {
  name             = "${var.env}-${var.slb_name}"
  vswitch_id       = "${var.vswitch_id}"
  master_zone_id   = "${var.master_zone_id}"
  slave_zone_id    = "${var.slave_zone_id}"
  specification    = "${var.specification}"
  internet         = "${var.internet}"
}

resource "alicloud_slb_listener" "tcp" {
  load_balancer_id          = "${alicloud_slb.slb.id}"
  backend_port              = 80
  frontend_port             = 80
  bandwidth                 = -1
  protocol                  = "tcp"
}