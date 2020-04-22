variable "vpc_id" {}

variable "rds_sg_name" {}

variable "rds_sg_description" {
  default = "Security Group managed by Terraform"
}

variable "inbound_rules" {
  type = "map"
}
variable "inbound_rules2" {
  type = "map"
}

variable "outbound_rules" {
  type = "map"
}

variable "env" {}

variable "accept_security_group_id" {
  default = "sg-12345"
}
# variable "rds_protocol" {
#   type = "string"
# }
# variable "rds_from_port" {
  
# }
# variable "rds_to_port" {
  
# }
