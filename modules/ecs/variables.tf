variable "env" {}

variable "instance_name" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "system_disk_category" {
  default = "cloud_efficiency"
}

variable "image_id" {
  type = "string"
}

variable "security_groups" {
  type = "list"
}

variable "availability_zone" {
  type = "string"
}

variable "vswitch_id" {
  type = "string"
}

variable "internet_max_bandwidth_out" {
  type = "string"
  default = "5"
}

variable "instance_charge_type" {
  type = "string"
  default = "PostPaid"
}


variable "password" {
  type = "string"
  default = "Xikai0test"
}