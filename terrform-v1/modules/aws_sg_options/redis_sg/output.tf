output "redis_sg_id" {
  value = "${aws_security_group.default_redis_sg.id}"
}

output "redis_sg_name" {
  value = "${aws_security_group.default_redis_sg.name}"
}
