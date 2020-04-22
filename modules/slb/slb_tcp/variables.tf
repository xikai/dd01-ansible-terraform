variable "env" {}

variable "slb_name" {}

variable "vswitch_id" {
  type = "string"
}

variable "master_zone_id" {}

variable "slave_zone_id" {}

variable "specification" {
  default = "slb.s1.small"
}

variable "internet" {
  default = "false"
}