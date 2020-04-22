resource "aws_lb" "alb" {
  name               = "${var.env}-${var.alb_name}-alb"
  internal           = false
  load_balancer_type = "application" #应用程序LB
  security_groups    = ["${var.alb_security_greoups}"]
  subnets            = ["${var.alb_subnets}"]

  tags {
    "Name"       = "${var.env}-${var.alb_name}"
    "Billing"    = "${var.env}"
    "BillingTag" = "${var.env}"
    "Team"       = "${var.alb_name}"
    "Project"     = "${var.alb_name}"
    "Environment" = "${var.env}"
  }  
} 
resource "aws_lb_target_group" "default" {
  name     = "${var.env}-${var.alb_name}-alb"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"    #default is instance
  vpc_id   = "${var.vpc_id}"
}


resource "aws_lb_listener" "default" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.alb_ssl_certificate_id}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.default.arn}"
  }
}

