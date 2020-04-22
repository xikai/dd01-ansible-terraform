provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "stag/service/huqiang"
  }
}

module "ec2_sg" {
  source                        = "../../modules/aws_sg/ec2_sg"

  env                           = "stag"  
  ec2_sg_name                   = "huqiang"
  vpc_id                        = "vpc-0cb62205eddd91563"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "80", "80", "TCP" ]
    "1" = [ "0.0.0.0/0", "443", "443","TCP" ]
    "2" = [ "0.0.0.0/0", "22", "22","TCP" ]    
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}

module "ec2" {
  source                             = "../../modules/ec2"

  env                                = "stag"
  ec2_ami                            = "ami-0eb1f21bbd66347fe"
  ec2_user                           = "ubuntu"
  ec2_key_name                       = "k8s-devops-1"
  ec2_instance_type                  = "t2.medium"
  ec2_name                           = "huqiang"
  ec2_volume_size                    = "30"
  ec2_volume_type                    = "gp2"
  ec2_iam_instance_profile           = "ansible-pull-stg"
  ec2_security_groups                = ["${module.ec2_sg.ec2_sg_id}"]
  ec2_subnet                         = "subnet-0405a8e2b3ed02c6e"
}  

