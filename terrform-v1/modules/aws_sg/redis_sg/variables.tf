variable "vpc_id" {}

variable "redis_sg_name" {}

variable "redis_sg_description" {
  default = "Security Group managed by Terraform"
}

variable "inbound_rules" {
  type = "map"
}

variable "outbound_rules" {
  type = "map"
}

variable "env" {}
