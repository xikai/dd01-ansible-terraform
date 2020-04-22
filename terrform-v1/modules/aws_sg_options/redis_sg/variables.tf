variable "vpc_id" {}

variable "redis_sg_name" {}

variable "redis_sg_description" {
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
variable "redis_protocol" {
  type = "string"
}
variable "redis_from_port" {
  
}
variable "redis_to_port" {
  
}