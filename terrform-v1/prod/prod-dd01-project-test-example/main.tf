provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "prod/service/project-test"
  }
}

# resource "aws_vpc" "vpc-np" {
#   cidr_block = "192.168.0.0/16"
#     tags {
#       "Name"        = "prod-stg-project-test-vpc"
#     }
# }

# resource "aws_internet_gateway" "gw-np" {
#   vpc_id = "${aws_vpc.vpc-np.id}"
#     tags {
#       "Name" = "prod-stg-project-test-igw"
#     }
# }
# resource "aws_route" "rt-np" {
#   route_table_id         = "${aws_vpc.vpc-np.main_route_table_id}"
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = "${aws_internet_gateway.gw-np.id}"
  # tags {
  #   "Name" = "prod-stg-project-test-route"
  # }
# }

# resource "aws_subnet" "sub-dmz-np" {
#   vpc_id                  = "${aws_vpc.vpc-np.id}"
#   cidr_block              = "192.168.1.0/24"
#   map_public_ip_on_launch = true
#   tags {
#       "Name"        = "prod-stg-project-test-subnet"
#     }
# }

module "ec2_sg" {
  source                        = "../../modules/aws_sg/ec2_sg"

  env                           = "prod"  
  ec2_sg_name                   = "project-test"
  vpc_id                        = "vpc-0f661a6b838378917"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "80", "80", "TCP" ]
    "1" = [ "0.0.0.0/0", "22", "22","TCP" ]    
    "2" = [ "0.0.0.0/0", "443", "443","TCP" ]   
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}
# module "elb" {
#   source                        = "../modules/elb"

#   env                           = "prod"  
#   elb_name                      = "stg-project-test"
#   elb_subnets                   = ["${aws_subnet.sub-dmz-np.id}"]
#   elb_security_groups           = ["${module.ec2_sg.ec2_sg_id}"]
#   elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:028586854543:certificate/d2a365e3-f427-4a23-85c0-a29f2f18370d"
#   elb_health_check_target       = "TCP:22"
# }
module "ec2" {
  source                             = "../../modules/ec2"

  env                                = "prod"
  # elb_name                           = "${module.elb.elb_name}"
  ec2_ami                            = "ami-0db47cd8e9a752ca0"
  ec2_user                           = "centos"
  ec2_key_name                       = "k8s-devops-1"
  ec2_instance_type                  = "c5.xlarge"
  ec2_name                           = "project-test"
  ec2_volume_size                    = "50"
  ec2_volume_type                    = "gp2"
  ec2_iam_instance_profile           = "ansible-pull-prod"
  ec2_security_groups                = ["${module.ec2_sg.ec2_sg_id}"]
  ec2_subnet                         = "subnet-011fb949d16bd16f3"
}  