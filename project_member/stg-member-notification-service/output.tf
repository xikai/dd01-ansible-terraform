output "slb_public_ip" {
  value = "${module.slb.slb_public_ip}"
}

output "rds_endpoint" {
  value = "${module.rds.rds_endpoint}"
}

output "redis_endpoint" {
  value = "${module.redis.redis_endpoint}"
}