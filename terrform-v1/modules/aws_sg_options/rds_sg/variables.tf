variable "vpc_id" {}

variable "rds_sg_name" {}

variable "rds_sg_description" {
  default = "Security Group managed by Terraform"
}

# variable "inbound_rules" {
#   type = "map"
# }

variable "outbound_rules" {
  type = "map"
}

variable "env" {}

variable "source_security_group_id" {
  default = "sg-1234"
}
variable "rds_protocol" {
  type = "string"
}
variable "rds_from_port" {
  
}
variable "rds_to_port" {
  
}
