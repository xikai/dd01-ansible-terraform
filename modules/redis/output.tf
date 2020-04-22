output "redis_id" {
  value = "${alicloud_kvstore_instance.redis.id}"
}

output "redis_endpoint" {
  value = "${alicloud_kvstore_instance.redis.connection_domain}"
}