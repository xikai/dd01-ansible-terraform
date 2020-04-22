resource "alicloud_slb" "slb" {
  name             = "${var.env}-${var.slb_name}"
  vswitch_id       = "${var.vswitch_id}"
  master_zone_id   = "${var.master_zone_id}"
  slave_zone_id    = "${var.slave_zone_id}"
  specification    = "${var.specification}"
  internet         = "${var.internet}"
}

resource "alicloud_slb_listener" "http" {
  load_balancer_id          = "${alicloud_slb.slb.id}"
  backend_port              = 80
  frontend_port             = 80
  bandwidth                 = -1
  protocol                  = "http"
  sticky_session            = "on"
  sticky_session_type       = "insert"
  cookie                    = "testslblistenercookie"
  cookie_timeout            = 86400
  health_check              = "on"
  health_check_type         = "http"
  health_check_connect_port = "80"
  health_check_uri          = "${var.health_check_uri}"
  health_check_http_code    = "${var.health_check_http_code}"
}