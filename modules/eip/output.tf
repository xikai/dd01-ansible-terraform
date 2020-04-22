output "eip_id" {
  value = "${alicloud_eip.eip.id}"
}

output "eip_address" {
  value = "${alicloud_eip.eip.ip_address}"
}