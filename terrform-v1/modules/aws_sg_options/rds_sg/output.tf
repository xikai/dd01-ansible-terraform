output "rds_sg_id" {
  value = "${aws_security_group.default_rds_sg.id}"
}

output "rds_sg_name" {
  value = "${aws_security_group.default_rds_sg.name}"
}
