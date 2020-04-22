resource "aws_security_group" "default_redis_sg" {
  name        = "${var.env}-${var.redis_sg_name}-redis"
  description = "${var.env}-${var.redis_sg_name} redis security rule"
  vpc_id      = "${var.vpc_id}"
  tags        = {
    "Name"        = "${var.env}-${var.redis_sg_name}-redis"
    "Project"     = "${var.redis_sg_name}"
    "Environment" = "${var.env}"
  }
}

# resource "aws_security_group_rule" "ingress_rule" {
#   count             = "${length(var.inbound_rules)}"
#   type              = "ingress"
#   cidr_blocks       = ["${element(var.inbound_rules[count.index], 0)}"]
#   from_port         = "${element(var.inbound_rules[count.index], 1)}"
#   to_port           = "${element(var.inbound_rules[count.index], 2)}"
#   protocol          = "${element(var.inbound_rules[count.index], 3)}"
#   security_group_id = "${aws_security_group.default_redis_sg.id}"
# }

resource "aws_security_group_rule" "ingress_rule" {  #使用安全组选项
  type              = "ingress"

  from_port         = "${var.redis_from_port}"
  to_port           = "${var.redis_to_port}"
  protocol          = "${var.redis_protocol}"
  security_group_id = "${aws_security_group.default_redis_sg.id}"
  source_security_group_id = "${var.source_security_group_id}"
}

resource "aws_security_group_rule" "egress_rule" {
  count             = "${length(var.outbound_rules)}"
  type              = "egress"
  cidr_blocks       = ["${element(var.outbound_rules[count.index], 0)}"]
  from_port         = "${element(var.outbound_rules[count.index], 1)}"
  to_port           = "${element(var.outbound_rules[count.index], 2)}"
  protocol          = "${element(var.outbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_redis_sg.id}"
}