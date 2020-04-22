provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "stag/service/dd01-stg-member-union-account"
  }
}

module "ec2_sg" {
  source                        = "../../modules/aws_sg/ec2_sg"

  env                           = "stag"  
  ec2_sg_name                   = "member-union-account"
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
module "redis_sg" {
  source                        = "../../modules/aws_sg/redis_sg"

  env                           = "stag"
  redis_sg_name                 = "terraform-test"
  vpc_id                        = "vpc-0cb62205eddd91563"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "6379", "6379", "TCP" ]   
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}
module "rds_sg" {
  source                        = "../../modules/aws_sg/rds_sg2"

  env                           = "stag"
  rds_sg_name                   = "member-union-account"
  vpc_id                        = "vpc-0cb62205eddd91563"

#   inbound_rules = {
#     "0" = ["0.0.0.0/0","3306", "3306", "TCP" ]
#   }
    rds_from_port = "3306"
    rds_to_port   = "3306"
    rds_protocol  = "TCP"
    source_security_group_id = "${module.ec2_sg.ec2_sg_id}"

  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}
module "elb" {
  source                        = "../../modules/elb"

  env                           = "stag"  
  elb_name                      = "member-union-account"
  elb_subnets                   = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"]
  elb_security_groups           = ["${module.ec2_sg.ec2_sg_id}"]
  elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:366222927764:certificate/632a1aa6-92bc-4e51-a4c3-6c7054a8a149"
  elb_health_check_target       = "TCP:22"
}
module "lc_asg" {
  source                             = "../../modules/lc_asg"

  env                                = "stag"
  elb_name                           = "${module.elb.elb_name}"
  lc_ami                             = "ami-0c80d7bb40e996535"
  lc_ami_user                        = "ubuntu"
  lc_ec2_key_name                    = "sz-dd01-rsa-1"
  lc_instance_type                   = "t3.medium"
  asg_name                           = "member-union-account"
  asg_desired_capacity               = "1"
  asg_min_size                       = "1"
  asg_max_size                       = "2"
  asg_volume_size                    = "30"
  asg_volume_type                    = "gp2"
  asp_target_value                   = "80.0"                           #弹性伸缩策略根据平均CPU利用率值
  asg_subnets                        = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"]
  cloudwatch_sns                     = "arn:aws:sns:ap-southeast-1:366222927764:weixin"
  lc_iam_instance_profile            = "ansible-pull-stg"
  lc_security_groups                 = ["${module.ec2_sg.ec2_sg_id}"]
  lc_userdata_ENV_HOME               = "/root"
  lc_userdata_ENV_SETUP_ENV          = "staging"
  lc_userdata_ENV_S3BUCKET_ENV       = "dd01-ansible-res"              #配置文件                
  lc_userdata_ENV_S3BUCKET_TERRAFORM = "dd01-ops-terraform-res"        #ansible-playbooks文件       
  lc_userdata_ENV_S3BUCKET_SSHPUBKEY = "dd01-ops-sshpubkey"            #密钥        

  lc_userdata_VAR_PLAYBOOKS = [
    "playbooks/common/common.yml",
    "playbooks/common/load-devops-keys.yml",
    "playbooks/common/load-dd01-keys.yml",
    "playbooks/projects/site-member-union-account.yml",
    "playbooks/common/cd-agent.yml",
  ]
}

module "cd_app" {
  source      = "../../modules/cd_app"
  cd_app_name = "stag-member-union-account-application"
}

resource "aws_codedeploy_deployment_group" "cd_group_conf" {
  app_name               = "stag-member-union-account-application"
  deployment_group_name  = "staging"
  service_role_arn       = "arn:aws:iam::366222927764:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups     = ["${module.lc_asg.asg_name}"]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }


  trigger_configuration {
    trigger_events     = ["DeploymentFailure", "DeploymentStart", "DeploymentSuccess", "DeploymentStop", "DeploymentReady", "DeploymentRollback"]
    trigger_name       = "sns to slack"
    trigger_target_arn = "arn:aws:sns:ap-southeast-1:366222927764:codedeploy-sns-slack"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}


module "redis" {
  source                            = "../../modules/redis_replica"
  
  env                               = "stag"
  name                              = "member-union-account"
  redis_clusters                    = "2"
  redis_failover                    = "true"
  redis_version                     = "3.2.10"
  redis_node_type                   = "cache.t2.micro"
  redis_security_group              = "${module.redis_sg.redis_sg_id}"
  redis_parameter_group_name        = "default.redis3.2" #cluster mode usage parameter group "default.redis3.2.cluster.on"
  subnets                           = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"]
  vpc_id                            = "vpc-0cb62205eddd91563" 
}
module "rds" {
  source = "../../modules/rds"

  env                               = "stag"
 
  rds_engine                        = "mysql"     #选项组|引擎
  rds_major_engine_version          = "5.7"       #选项组|主引擎版本

  rds_engine_version                = "5.7.17"
  rds_allocated_storage             = "30"
  rds_storage_type                  = "gp2"
  rds_iops                          = "0"  
  rds_instance_class                = "db.t2.small"
  rds_identifier                    = "member-union-account"
  rds_username                      = "superadmin"
  rds_password_payload              = "AQICAHitYQE0hKiwrv54Fr6Fg1X6PagRY+eKbzkzcP0b5RzJiQHYC8xEimv9cixoMR8MiZHpAAAAejB4BgkqhkiG9w0BBwagazBpAgEAMGQGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM/V6FDMmQxed3K6mwAgEQgDfV/14C+9SnQljS9HbHYTmyI9VMJvlBy9O9CjuC/1s4foDTaq+KYotERUl5U4wQG5UWwvzshHkY"
  rds_backup_retention_period       = "7"
  rds_multi_az                      = true
  rds_skip_final_snapshot           = false
  rds_vpc_security_group_ids        = "${module.rds_sg.rds_sg_id}"
  rds_publicly_accessible           = true      #不公开访问
  rds_subnet_ids                    = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"] #子网组|子网列表

  rds_family                        = "mysql5.7"  #参数组|数据库系列
  rds_parameters = [                              #参数组|自定义参数
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    },
    {
      name  = "collation_server"
      value = "utf8_general_ci"
    },
    {
      name  = "max_connect_errors"
      value = "100000"
    }
  ]  
}

