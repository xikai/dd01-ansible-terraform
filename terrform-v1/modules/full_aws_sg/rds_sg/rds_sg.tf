resource "aws_security_group" "default_rds_sg" {
  name        = "${var.env}-${var.rds_sg_name}-rds"
  description = "${var.env}-${var.rds_sg_name} rds security rule"
  vpc_id      = "${var.vpc_id}"
  tags        = {
    "Name"        = "${var.env}-${var.rds_sg_name}-rds"
    "Project"     = "${var.rds_sg_name}"
    "Environment" = "${var.env}"
  }
}

resource "aws_security_group_rule" "ingress_rule" { #使用CIDR块列表
  count             = "${length(var.inbound_rules)}"
  type              = "ingress"
  cidr_blocks       = ["${element(var.inbound_rules[count.index], 0)}"]
  from_port         = "${element(var.inbound_rules[count.index], 1)}"
  to_port           = "${element(var.inbound_rules[count.index], 2)}"
  protocol          = "${element(var.inbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_rds_sg.id}"
}

# resource "aws_security_group_rule" "ingress_rule" {  #使用安全组选项
#   type              = "ingress"

#   from_port         = "${var.rds_from_port}"
#   to_port           = "${var.rds_to_port}"
#   protocol          = "${var.rds_protocol}"
#   security_group_id = "${aws_security_group.default_rds_sg.id}"
#   source_security_group_id = "${var.source_security_group_id}"
# }

resource "aws_security_group_rule" "egress_rule" {
  count             = "${length(var.outbound_rules)}"
  type              = "egress"
  cidr_blocks       = ["${element(var.outbound_rules[count.index], 0)}"]
  from_port         = "${element(var.outbound_rules[count.index], 1)}"
  to_port           = "${element(var.outbound_rules[count.index], 2)}"
  protocol          = "${element(var.outbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_rds_sg.id}"
}