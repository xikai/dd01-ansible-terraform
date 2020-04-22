output "elb_name" {
  value = "${aws_elb.elb_conf.name}"
}

output "elb_dns_name" {
  value = "${aws_elb.elb_conf.dns_name}"
}
