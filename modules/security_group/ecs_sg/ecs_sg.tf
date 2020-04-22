resource "alicloud_security_group" "ecs_sg" {
  name        = "${var.env}-${var.ecs_sg_name}-sg"
  description = "${var.env}-${var.ecs_sg_name} security group rule"
  vpc_id      = "${var.vpc_id}"

  tags        = {
    "Name"        = "${var.env}-${var.ecs_sg_name}-sg"
    "Environment" = "${var.env}"
  }
}

resource "alicloud_security_group_rule" "ingress_rule" {
  count             = "${length(var.inbound_rules)}"
  type              = "ingress"
  ip_protocol       = "${element(var.inbound_rules[count.index], 0)}"
  port_range        = "${element(var.inbound_rules[count.index], 1)}"
  cidr_ip           = "${element(var.inbound_rules[count.index], 2)}"
  security_group_id = "${alicloud_security_group.ecs_sg.id}"
}

resource "alicloud_security_group_rule" "egress_rule" {
  count             = "${length(var.outbound_rules)}"
  type              = "egress"
  ip_protocol       = "${element(var.inbound_rules[count.index], 0)}"
  port_range        = "${element(var.inbound_rules[count.index], 1)}"
  cidr_ip           = "${element(var.inbound_rules[count.index], 2)}"
  security_group_id = "${alicloud_security_group.ecs_sg.id}"
}