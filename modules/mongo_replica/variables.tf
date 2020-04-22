variable "env" {}

variable "name" {}

variable "engine_version" {}

variable "db_instance_class" {}

variable "db_instance_storage" {}

variable "replication_factor" {
  default = "3"
}

variable "storage_engine" {
  default = "WiredTiger"
}

#variable "zone_id" {}

variable "vswitch_id" {}

variable "account_password" {}

variable "security_ip_list" {
  type = "list"
}