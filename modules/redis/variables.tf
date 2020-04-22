variable "env" {}

variable "instance_name" {}

variable "engine" {}

variable "engine_version" {}

variable "instance_class" {}

variable "password" {}

#variable "availability_zone" {}

variable "vswitch_id" {}

variable "security_ips" {
  type = "list"
}