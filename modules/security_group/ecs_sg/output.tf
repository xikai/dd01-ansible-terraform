output "ecs_sg_id" {
  value = "${alicloud_security_group.ecs_sg.id}"
}

output "ecs_sg_name" {
  value = "${alicloud_security_group.ecs_sg.name}"
}
