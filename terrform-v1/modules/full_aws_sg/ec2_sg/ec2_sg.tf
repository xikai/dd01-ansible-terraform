resource "aws_security_group" "default_ec2_sg" {
  name        = "${var.env}-${var.ec2_sg_name}-elb"
  description = "${var.env}-${var.ec2_sg_name} elb security rule"
  vpc_id      = "${var.vpc_id}"
  tags        = {
    "Name"        = "${var.env}-${var.ec2_sg_name}-elb"
    "Project"     = "${var.ec2_sg_name}"
    "Environment" = "${var.env}"
  }
}

resource "aws_security_group_rule" "ingress_rule" {
  count             = "${length(var.inbound_rules)}"
  type              = "ingress"
  cidr_blocks       = ["${element(var.inbound_rules[count.index], 0)}"]
  from_port         = "${element(var.inbound_rules[count.index], 1)}"
  to_port           = "${element(var.inbound_rules[count.index], 2)}"
  protocol          = "${element(var.inbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_ec2_sg.id}"
}

resource "aws_security_group_rule" "egress_rule" {
  count             = "${length(var.outbound_rules)}"
  type              = "egress"
  cidr_blocks       = ["${element(var.outbound_rules[count.index], 0)}"]
  from_port         = "${element(var.outbound_rules[count.index], 1)}"
  to_port           = "${element(var.outbound_rules[count.index], 2)}"
  protocol          = "${element(var.outbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_ec2_sg.id}"
}