variable "vpc_id" {}

variable "ec2_sg_name" {}

variable "ec2_sg_description" {
  default = "Security Group managed by Terraform"
}

variable "inbound_rules" {
  type = "map"
}


variable "outbound_rules" {
  type = "map"
}
variable "env" {}
