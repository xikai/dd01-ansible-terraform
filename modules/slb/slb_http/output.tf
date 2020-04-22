output "slb_id"{
  value = "${alicloud_slb.slb.id}"
}

output "slb_public_ip"{
  value = "${alicloud_slb.slb.address}"
}