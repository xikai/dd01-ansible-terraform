output "dd01_sg_id" {
  value = "${aws_security_group.default_dd01_sg.id}"
}

output "project_name" {
  value = "${var.project_name}"
}
output "vpc_id" {
  value = "${var.vpc_id}"
}
output "subnets" {
  value = "${var.subnets}"
}
output "billing_team" {
  value = "${var.billing_team}"
}
output "env" {
  value = "${var.env}"
}
output "asg_name" {
  value = "${aws_autoscaling_group.asg_conf.name}"
}
