provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "stag/service/dd01-stg-project-test"
  }
}

module "platform" {
  source                        = "../../modules/platform"

  env                           = "stag"  
  project_name                  = "project-test"
  billing_team                  = "member"
  vpc_id                        = "vpc-0cb62205eddd91563"
  subnets                       = ["subnet-03640fc8791c09e3f","subnet-0405a8e2b3ed02c6e","subnet-0db6407e7898da68c"]

  #Security Group
  inbound_rules = {
    "0" = [ "0.0.0.0/0", "80", "80", "TCP" ]
    "1" = [ "0.0.0.0/0", "443", "443","TCP" ]  
    "2" = [ "0.0.0.0/0", "22", "22","TCP" ] 
    "3" = [ "116.92.128.226/32", "3306", "3306","TCP" ] 
  } 

  #ELB
  elb_name                      = "project-test" #long size limit
  elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:366222927764:certificate/632a1aa6-92bc-4e51-a4c3-6c7054a8a149"
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
    "playbooks/projects/site-project-test.yml",
    "playbooks/common/cd-agent.yml",
  ]
}

//放行adminer连接3306
resource "aws_security_group_rule" "sg_ingress_rule" {  
  type              = "ingress"

  from_port         = "3306"
  to_port           = "3306"
  protocol          = "TCP"
  security_group_id = "${module.platform.dd01_sg_id}"
  source_security_group_id = "sg-0ccd143bebb9ae784"   //允许放行的安全组
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

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
###Redis 
# module "redis" {
#   source                            = "../../modules/redis_replica"
  
#   env                               = "${module.platform.env}"
#   name                              = "${module.platform.project_name}"
#   billing_team                      = "${module.platform.billing_team}"
#   redis_clusters                    = "2"
#   redis_failover                    = "true"
#   redis_version                     = "3.2.10"
#   redis_node_type                   = "cache.m3.medium"
#   redis_security_group              = "${module.platform.dd01_sg_id}"
#   redis_parameter_group_name        = "default.redis3.2" #cluster mode usage parameter group "default.redis3.2.cluster.on"
#   subnets                           = ["${module.platform.subnets}"]
#   vpc_id                            = "${module.platform.vpc_id}" 
# }

###RDS Mysql
# module "rds" {
#   source                            = "../../modules/rds_mysql"

#   env                               = "${module.platform.env}"
#   billing_team                      = "${module.platform.billing_team}"
 
#   rds_engine                        = "mysql"     #选项组|引擎
#   rds_major_engine_version          = "5.7"       #选项组|主引擎版本

#   rds_engine_version                = "5.7.17"
#   rds_allocated_storage             = "100"
#   rds_storage_type                  = "gp2"
#   rds_iops                          = "0"  
#   rds_instance_class                = "db.m4.xlarge"
#   rds_identifier                    = "${module.platform.project_name}"
#   rds_username                      = "superadmin"
#   rds_password_payload              = "AQICAHitYQE0hKiwrv54Fr6Fg1X6PagRY+eKbzkzcP0b5RzJiQFN0Rptva/wfPQHrgQE+DUTAAAAejB4BgkqhkiG9w0BBwagazBpAgEAMGQGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMp2oIAauxrK4xYZWNAgEQgDfklenjhcKAzZ1Sszrs6WzWevD8qCsbbsOK8sEqYPsH4BKJk0tg9xuzoWFWVKtOYg51D4xp2Mbb"
#   rds_backup_retention_period       = "7"
#   rds_multi_az                      = true
#   rds_skip_final_snapshot           = false
#   rds_vpc_security_group_ids        = "${module.platform.dd01_sg_id}"
#   rds_publicly_accessible           = false      #不公开访问
#   rds_subnet_ids                    = ["${module.platform.subnets}"] #子网组|子网列表

#   rds_family                        = "mysql5.7"  #参数组|数据库系列
#   rds_parameters = [                              #参数组|自定义参数
#     {
#       name  = "character_set_client"
#       value = "utf8mb4"
#     },
#     {
#       name  = "character_set_server"
#       value = "utf8mb4"
#     },
#     {
#       name  = "collation_server"
#       value = "utf8mb4_general_ci"
#     },
#     {
#       name  = "max_connect_errors"
#       value = "100000"
#     },
#     {
#       name  = "slow_query_log"
#       value = "1"
#     },
#     {
#       name  = "slow_launch_time"
#       value = "2"
#     }
#   ]  
#   # rds_options = [                               #选项组|自定义添加选项,删除选项组需要先删除所有相关快照，再等待一段时间才能最终删除
#   #   {
#   #     option_name = "MARIADB_AUDIT_PLUGIN"
#   #     option_settings = [
#   #       {
#   #         name  = "SERVER_AUDIT_EVENTS"
#   #         value = "CONNECT"
#   #       },
#   #       {
#   #         name  = "SERVER_AUDIT_FILE_ROTATIONS"
#   #         value = "37"
#   #       },
#   #     ]
#   #   },
#   # ]
# }