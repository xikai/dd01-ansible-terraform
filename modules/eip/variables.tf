variable "env" {}

variable "eip_name" {}

variable "bandwidth" {
    default = "5"
}

variable "internet_charge_type" {
  default = "PayByTraffic"
}

variable "instance_id" {}