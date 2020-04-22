provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01hk-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01hk-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "prod/service/dd01hk-ec-cps-frontend"
  }
}

module "ec2_sg" {
  source                        = "../../modules/aws_sg/ec2_sg"

  env                           = "prod"  
  ec2_sg_name                   = "dd01hk-ec-cps-frontend"
  vpc_id                        = "vpc-02747f51527684fcc"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "443", "443","TCP" ]
    "1" = [ "0.0.0.0/0", "22", "22","TCP" ]    
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}


module "elb" {
  source                        = "../../modules/elb"

  env                           = "prod"  
  elb_name                      = "ec-cps-frontend"
  elb_subnets                   = ["subnet-09357374c405686d7","subnet-095a0b306136da598","subnet-0707c686beaa39f8b"]
  elb_security_groups           = ["${module.ec2_sg.ec2_sg_id}"]
  elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:028586854543:certificate/f34a58e5-fc8c-4fa0-a1eb-060bf60b99b1"
  elb_health_check_target       = "TCP:22"
  elb_access_logs = {
    enabled = true
    bucket  = "dd01hk-aws-logs"
    interval = 5
  }
}

module "lc_asg" {
  source                             = "../../modules/dd01hk_lc_asg"

  env                                = "prod"
  elb_name                           = "${module.elb.elb_name}"
  lc_ami                             = "ami-0933968a713166843"
  lc_ami_user                        = "ubuntu"
  lc_ec2_key_name                    = "dd01-ops-1"
  lc_instance_type                   = "t3.small"
  asg_name                           = "ec-cps-frontend"
  asg_desired_capacity               = "2"
  asg_min_size                       = "2"
  asg_max_size                       = "4"
  asg_volume_size                    = "30"
  asg_volume_type                    = "gp2"
  asp_target_value                   = "80.0"                           #弹性伸缩策略根据平均CPU利用率值
  asg_subnets                        = ["subnet-09357374c405686d7","subnet-095a0b306136da598","subnet-0707c686beaa39f8b"]
  cloudwatch_sns                     = "arn:aws:sns:ap-southeast-1:028586854543:weixin"  
  lc_iam_instance_profile            = "ansible-pull-prod"
  lc_security_groups                 = ["${module.ec2_sg.ec2_sg_id}"]
  lc_userdata_ENV_HOME               = "/root"
  lc_userdata_ENV_SETUP_ENV          = "production"
  lc_userdata_ENV_S3BUCKET_ENV       = "dd01hk-ansible-res-prod"              #配置文件                
  lc_userdata_ENV_S3BUCKET_TERRAFORM = "dd01hk-ops-terraform-res"        #ansible-playbooks文件       
  lc_userdata_ENV_S3BUCKET_SSHPUBKEY = "dd01hk-ops-sshpubkey"            #密钥        

  lc_userdata_VAR_PLAYBOOKS = [
    "playbooks/common/common.yml",
    "playbooks/common/load-dd01-keys.yml",
    "playbooks/common/load-devops-keys.yml",
    "playbooks/common/cd-agent.yml",
    "playbooks/projects/site-ec-cps-frontend.yml",
  ]
}

module "cd_app" {
  source      = "../../modules/cd_app"
  cd_app_name = "prod-ec-cps-frontend-application"
}

resource "aws_codedeploy_deployment_group" "cd_group_conf" {
  app_name               = "prod-ec-cps-frontend-application"
  deployment_group_name  = "production"
  service_role_arn       = "arn:aws:iam::028586854543:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups     = ["${module.lc_asg.asg_name}"]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }


  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentStart", "DeploymentSuccess", "DeploymentStop", "DeploymentReady", "DeploymentRollback"]
    trigger_name       = "sns to slack"
    trigger_target_arn = "arn:aws:sns:ap-southeast-1:028586854543:codedeploy-sns-slack"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

module "cd_app2" {
  source      = "../../modules/cd_app"
  cd_app_name = "prod-ec-index-application"
}

resource "aws_codedeploy_deployment_group" "cd_group_conf2" {
  app_name               = "prod-ec-index-application"
  deployment_group_name  = "production"
  service_role_arn       = "arn:aws:iam::028586854543:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups     = ["${module.lc_asg.asg_name}"]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }


  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentStart", "DeploymentSuccess", "DeploymentStop", "DeploymentReady", "DeploymentRollback"]
    trigger_name       = "sns to slack"
    trigger_target_arn = "arn:aws:sns:ap-southeast-1:028586854543:codedeploy-sns-slack"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}


data "aws_iam_policy_document" "s3_cf_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_conf.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_cf_identity" {
  bucket = "${aws_s3_bucket.s3_conf.id}"
  policy = "${data.aws_iam_policy_document.s3_cf_policy.json}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "prod ec-cps-frontend"
}
resource "aws_s3_bucket" "s3_conf" {
  region = "ap-southeast-1"
  bucket = "dd01hk-prod-ec-cps-frontend"
  acl    = "private"
  tags = {
    Team = "ec"
    Billing = "prod"
  }
}

