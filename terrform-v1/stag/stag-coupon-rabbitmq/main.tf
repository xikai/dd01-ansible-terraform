provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "stag/service/coupon-rabbitmq"
  }
}

module "ec2_sg" {
  source                        = "../../modules/aws_sg/ec2_sg"

  env                           = "stag"  
  ec2_sg_name                   = "coupon-rabbitmq"
  vpc_id                        = "vpc-0cb62205eddd91563"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "22", "22","TCP" ]
    "1" = [ "0.0.0.0/0", "5672", "5672","TCP" ]
    "2" = [ "0.0.0.0/0", "15672", "15672","TCP" ]    
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}
# module "elb" {
#   source                        = "../modules/elb"

#   env                           = "stag"  
#   elb_name                      = "stg-coupon-rabbitmq"
#   elb_subnets                   = ["${aws_subnet.sub-dmz-np.id}"]
#   elb_security_groups           = ["${module.ec2_sg.ec2_sg_id}"]
#   elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:028586854543:certificate/d2a365e3-f427-4a23-85c0-a29f2f18370d"
#   elb_health_check_target       = "TCP:22"
# }
module "ec2" {
  source                             = "../../modules/ec2"

  env                                = "stag"
  # elb_name                           = "${module.elb.elb_name}"
  ec2_ami                            = "ami-0db47cd8e9a752ca0"
  ec2_user                           = "centos"
  ec2_key_name                       = "aws-dd01-rsa"
  ec2_instance_type                  = "t3.small"
  ec2_name                           = "coupon-rabbitmq"
  ec2_volume_size                    = "50"
  ec2_volume_type                    = "gp2"
  ec2_iam_instance_profile           = "ansible-pull-stg"
  ec2_security_groups                = ["${module.ec2_sg.ec2_sg_id}"]
  ec2_subnet                         = "subnet-0405a8e2b3ed02c6e"
}  