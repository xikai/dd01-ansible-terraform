variable "vpc_cidr_block" {
  description = "The top-level CIDR block for the VPC."
  default     = "172.16.0.0/16"
}

variable "cidr_blocks" {
  description = "The CIDR blocks to create the workstations in."
  default     = ["172.16.10.0/24", "172.16.20.0/24","172.16.30.0/24"]
}

variable "vpc_name" {
  description = "Default namespace"
}
variable "internet_gateway_name" {
  description = "Default namespace"
}

variable "subnet_name" {
  default = "default"
}
variable "env" {
  description = "Define the build environment"
}

variable "route_name" {
  default = "default"
}
