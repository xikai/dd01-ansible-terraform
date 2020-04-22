variable "env" {}

variable "scaling_group_name" {}

variable "min_size" {}

variable "max_size" {}

variable "vswitch_ids" {
  type = "list"
}

variable "loadbalancer_ids" {
  type = "list"
}

variable "db_instance_ids" {
  type = "list"
}

variable "multi_az_policy" {}

variable "instance_name" {}

variable "instance_type" {}

variable "image_id" {}

variable "system_disk_category" {
  default = "cloud_efficiency"
}

variable "system_disk_size" {
  default = "40"
}

variable "key_name" {}

variable "role_name" {}

variable "security_group_id" {}

variable "userdata_CODE_SERVER" {}

variable "userdata_ENV_HOME" {}

variable "userdata_OSS_ANSIBLE" {}

variable "userdata_VAR_PLAYBOOKS" {
  type = "list"
}


variable "adjustment_type" {}

variable "adjustment_value" {}