variable "env" {}

variable "vpc_id" {}

variable "ecs_sg_name" {}

variable "ecs_sg_description" {
  default = "Security Group managed by Terraform"
}

variable "inbound_rules" {
  type = "map"
}

variable "outbound_rules" {
  type = "map"
}

