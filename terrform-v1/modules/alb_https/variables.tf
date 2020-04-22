variable "alb_name" {
  type = "string"
}

variable "alb_security_greoups" {
  type = "list"
}

variable "alb_subnets" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

# variable "alb_tag_billing" {
#   type = "string"
# }

# variable "alb_tag_team" {
#   type = "string"
# }

variable "alb_ssl_certificate_id" {
  type = "string"
}
variable "alb_tg_name" {
  type    = "string"
  default = ""
}

variable "env" {
  type = "string"
}