### Creating ELB
resource "aws_elb" "elb_conf" {
  name            = "${var.env}-${var.elb_name}-elb"
  internal        = false
  subnets         = ["${var.elb_subnets}"]
  security_groups = ["${var.elb_security_groups}"]

  access_logs = ["${var.elb_access_logs}"]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "${var.elb_health_check_target}"
  }
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = "80"
    instance_protocol  = "http"
    ssl_certificate_id = "${var.elb_ssl_certificate_id}"
  }
  tags {
    "Name"       = "${var.env}-${var.elb_name}"
    "Billing"    = "${var.env}"
    "BillingTag" = "${var.env}"
    "Team"       = "${var.elb_name}"
    "Project"     = "${var.elb_name}"
    "Environment" = "${var.env}"
  }
}
