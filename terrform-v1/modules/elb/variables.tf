variable "elb_name" {
  type    = "string"
}

variable "elb_subnets" {
  type    = "list"
}

variable "elb_security_groups" {
  type = "list"
}


variable "elb_ssl_certificate_id" {
  type = "string"
  default = ""
}

variable "elb_health_check_target" {
  type = "string"
  default = "TCP:80"
}

variable "elb_access_logs" {
  type = "map"
  default = {
    enabled = false
    bucket = "dd01-aws-logs"
    bucket_prefix = ""
    interval  = 60
  }
}

variable "env" {
  type = "string"
}
