###security group variables
variable "env" {}
variable "vpc_id" {}
variable "project_name" {}
variable "dd01_sg_description" {
  default = "Security Group managed by Terraform"
}
variable "inbound_rules" {
  type = "map"
}

####elb variables
variable "elb_name" {
  type    = "string"
}
variable "subnets" {
  type    = "list"
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
  }
}
variable "billing_team" {
}

###auto scaling variables
variable "region" {
  type        = "string"
  default     = "ap-southeast-1"
  description = "The target AWS region for the cluster."
}

variable "aws_access_key" {
  type        = "string"
  default     = ""
  description = "default is read only, define your key in secret.tfvars."
}

variable "aws_secret_key" {
  type        = "string"
  default     = ""
  description = "default is read only, define your key in secret.tfvars."
}

variable "lc_ec2_key_name" {
  type    = "string"
  default = "dev-intsys"
}

variable "lc_instance_type" {
  type    = "string"
  default = "t2.micro"
}

variable "lc_ami" {
  type    = "string"
  default = "ami-e32f7f9"
}

variable "lc_ami_user" {
  type    = "string"
  default = "ubuntu"
}


variable "lc_userdata_ENV_HOME" {
  type = "string"
}

variable "lc_userdata_ENV_SETUP_ENV" {
  type = "string"
}


variable "lc_userdata_ENV_S3BUCKET_ENV" {
  type = "string"
}

variable "lc_userdata_ENV_S3BUCKET_TERRAFORM" {
  type = "string"
}

variable "lc_userdata_ENV_S3BUCKET_SSHPUBKEY" {
  default = "string"
}

variable "lc_userdata_VAR_PLAYBOOKS" {
  type = "list"
}

variable "lc_iam_instance_profile" {
  type = "string"
}

variable "asg_min_size" {
  type    = "string"
  default = "1"
}

variable "asg_max_size" {
  type    = "string"
  default = "2"
}

variable "asg_desired_capacity" {
  type    = "string"
  default = "1"
}

variable "asg_volume_size" {
  type    = "string"
  default = "30"
}

variable "asg_volume_type" {
  type    = "string"
  default = "gp2"
}

variable "asp_target_value" {
  default = "75.0"
}

variable "cloudwatch_sns" { 
}
