provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "stag/service/dd01-stg-member-sso-web"
  }
}

module "platform" {
  source                        = "../../modules/platform"

  env                           = "stag"  
  project_name                  = "member-sso-web"
  billing_team                  = "member"
  vpc_id                        = "vpc-0cb62205eddd91563"
  subnets                       = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"]

  #Security Group
  inbound_rules = {
    "0" = [ "0.0.0.0/0", "443", "443","TCP" ]  
    "1" = [ "0.0.0.0/0", "22", "22","TCP" ] 
  } 

  #ELB
  elb_name                      = "member-sso-web" #long size limit
  elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:366222927764:certificate/1b6d3911-f835-40f3-9e17-41416cfc3653"
  elb_health_check_target       = "TCP:22"
  
  #Auto Scaling
  lc_ami                             = "ami-0933968a713166843"
  lc_ami_user                        = "ubuntu"
  lc_ec2_key_name                    = "sz-dd01-rsa-1"
  lc_instance_type                   = "t3.medium"
  asg_desired_capacity               = "1"
  asg_min_size                       = "1"
  asg_max_size                       = "2"
  asg_volume_size                    = "30"
  asg_volume_type                    = "gp2"
  asp_target_value                   = "80.0"                           #弹性伸缩策略根据平均CPU利用率值
  cloudwatch_sns                     = "arn:aws:sns:ap-southeast-1:366222927764:weixin"
  lc_iam_instance_profile            = "ansible-pull-stg"
  lc_userdata_ENV_HOME               = "/root"
  lc_userdata_ENV_SETUP_ENV          = "staging"                       #结合CodeDeploy部署组名称
  lc_userdata_ENV_S3BUCKET_ENV       = "dd01-ansible-res"              #配置文件                
  lc_userdata_ENV_S3BUCKET_TERRAFORM = "dd01-ops-terraform-res"        #ansible-playbooks文件       
  lc_userdata_ENV_S3BUCKET_SSHPUBKEY = "dd01-ops-sshpubkey"            #密钥        

  lc_userdata_VAR_PLAYBOOKS = [
    "playbooks/common/common.yml",
    "playbooks/common/load-devops-keys.yml",
    "playbooks/common/load-dd01-keys.yml",
    "playbooks/projects/site-member-sso-web.yml",
    "playbooks/common/cd-agent.yml",
  ]
}

###CodeDeploy 
resource "aws_codedeploy_app" "cd_app_conf" {
  name = "${module.platform.env}-${module.platform.project_name}-application"
}

resource "aws_codedeploy_deployment_group" "cd_group_conf" {
  app_name               = "${module.platform.env}-${module.platform.project_name}-application"
  deployment_group_name  = "staging"
  service_role_arn       = "arn:aws:iam::366222927764:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups     = ["${module.platform.asg_name}"]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }


  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentStart", "DeploymentSuccess", "DeploymentStop", "DeploymentReady", "DeploymentRollback"]
    trigger_name       = "sns to slack"
    trigger_target_arn = "arn:aws:sns:ap-southeast-1:366222927764:codedeploy-sns-slack"
  }
  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentStart", "DeploymentSuccess", "DeploymentStop", "DeploymentReady", "DeploymentRollback"]
    trigger_name       = "sns to dingding"
    trigger_target_arn = "arn:aws:sns:ap-southeast-1:366222927764:codedeploy-sns-dingding"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
