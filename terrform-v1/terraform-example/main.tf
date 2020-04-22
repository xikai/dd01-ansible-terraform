provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt                     = true
    bucket                      = "dd01hk-terraform-remote-state-storage-s3"
    dynamodb_table              = "dd01hk-terraform-state-lock-dynamo"
    region                      = "ap-southeast-1"
    key                         = "stag/service/terraform-test"
  }
}

module "vpc" {
  source                        = "../modules/vpc"

  env                           = "stag"
  subnet_name                   = "terraform-test"
  vpc_name                      = "terraform-test"   
  internet_gateway_name         = "terraform-test"
  route_name                    = "terraform-test"
  vpc_cidr_block                = "172.16.0.0/16"
  cidr_blocks                   = ["172.16.10.0/24", "172.16.20.0/24","172.16.30.0/24"]
}

module "rds_sg" {
  source                        = "../modules/aws_sg/rds_sg"

  env                           = "stag"
  rds_sg_name                   = "terraform-test"
  vpc_id                        = "${module.vpc.vpc_id}"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "3306", "3306", "TCP" ]
    "1" = ["54.254.181.15/32","3306","3306","TCP"]   #accept Adminer server access 3306
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}


module "ec2_sg" {
  source                        = "../modules/aws_sg/ec2_sg"

  env                           = "stag"  
  ec2_sg_name                   = "terraform-test"
  vpc_id                        = "${module.vpc.vpc_id}"

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
  source                        = "../modules/aws_sg/redis_sg"

  env                           = "stag"
  redis_sg_name                 = "terraform-test"
  vpc_id                        = "${module.vpc.vpc_id}"

  inbound_rules = {
    "0" = [ "0.0.0.0/0", "6379", "6379", "TCP" ]   
  }
  outbound_rules = {
    "0" = [ "0.0.0.0/0", "0", "0", "-1" ]
  }  
}

module "elb" {
  source                        = "../modules/elb"

  env                           = "stag"  
  elb_name                      = "terraform-test"
  elb_subnets                   = ["${module.vpc.subnet_id}","${module.vpc.subnet_id}","${module.vpc.subnet_id}"]
  elb_security_groups           = ["${module.ec2_sg.ec2_sg_id}"]
  elb_ssl_certificate_id        = "arn:aws:acm:ap-southeast-1:028586854543:certificate/d2a365e3-f427-4a23-85c0-a29f2f18370d"
  elb_health_check_target       = "TCP:22"
}

module "lc_asg" {
  source                             = "../modules/lc_asg"

  env                                = "stag"
  elb_name                           = "${module.elb.elb_name}"
  lc_ami                             = "ami-011b122069c54cf60"
  lc_ami_user                        = "ubuntu"
  lc_ec2_key_name                    = "dd01-ops-1"
  lc_instance_type                   = "t2.small"
  asg_name                           = "project-test"
  asg_desired_capacity               = "1"
  asg_min_size                       = "1"
  asg_max_size                       = "2"
  asg_volume_size                    = "30"
  asg_volume_type                    = "gp2"
  asp_target_value                   = "80.0"                           #弹性伸缩策略根据平均CPU利用率值
  asg_subnets                        = ["${module.vpc.subnet_id}","${module.vpc.subnet_id}","${module.vpc.subnet_id}"]
  lc_iam_instance_profile            = "ansible-pull"
  lc_security_groups                 = ["${module.ec2_sg.ec2_sg_id}"]
  lc_userdata_ENV_HOME               = "/root"
  lc_userdata_ENV_SETUP_ENV          = "staging"
  lc_userdata_ENV_S3BUCKET_ENV       = "dd01hk-ansible-res"              #配置文件                
  lc_userdata_ENV_S3BUCKET_TERRAFORM = "dd01hk-ops-terraform-res"        #ansible-playbooks文件       
  lc_userdata_ENV_S3BUCKET_SSHPUBKEY = "dd01hk-ops-sshpubkey"            #密钥        

  lc_userdata_VAR_PLAYBOOKS = [
    "playbooks/common/common.yml",
    "playbooks/common/load-dd01-keys.yml",
    "playbooks/common/load-devops-keys.yml",
    "playbooks/common/cd-agent.yml",
    "playbooks/projects/site-project-test.yml",
  ]
}


module "redis" {
  source                            = "../modules/redis_replica"
  
  env                               = "stag"
  name                              = "terraform-test"
  redis_clusters                    = "2"
  redis_failover                    = "true"
  redis_version                     = "3.2.10"
  redis_node_type                   = "cache.t2.micro"
  redis_security_group              = "${module.redis_sg.redis_sg_id}"
  redis_parameter_group_name        = "default.redis3.2" #cluster mode usage parameter group "default.redis3.2.cluster.on"
  subnets                           = ["${module.vpc.subnet_id}","${module.vpc.subnet_id}","${module.vpc.subnet_id}"]
  vpc_id                            = "${module.vpc.vpc_id}" 
}
module "rds" {
  source = "../modules/rds"

  env                               = "stag"
 
  rds_engine                        = "mysql"     #选项组|引擎
  rds_major_engine_version          = "5.7"       #选项组|主引擎版本

  rds_engine_version                = "5.7.17"
  rds_allocated_storage             = "30"
  rds_storage_type                  = "gp2"
  rds_iops                          = "0"  
  rds_instance_class                = "db.t2.small"
  rds_identifier                    = "terraform-test"
  rds_username                      = "superadmin"
  rds_password_payload              = "AQICAHhp9qDg2zmrjcOWHvU8CmDthlFw0q4BBJiNzR/cXQ6lwQGgyYtCXbyFe6Q6z0oOKeymAAAAejB4BgkqhkiG9w0BBwagazBpAgEAMGQGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM4iS/nI0hWzpPONQKAgEQgDfO0NYjVX1E8rV4tvcxEEDQwSzxFWHBJMMuc7u+LChQghMBKp8dwd63A/Ld+41NvySkZ3QuSQ0n"
  rds_backup_retention_period       = "7"
  rds_multi_az                      = true
  rds_skip_final_snapshot           = false
  rds_vpc_security_group_ids        = "${module.rds_sg.rds_sg_id}"
  rds_publicly_accessible           = false      #不公开访问
  rds_subnet_ids                    = ["${module.vpc.subnet_id}","${module.vpc.subnet_id}","${module.vpc.subnet_id}"] #子网组|子网列表

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
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "slow_launch_time"
      value = "2"
    }
  ]  
  # rds_options = [                               #选项组|自定义添加选项
  #   {
  #     option_name = "MARIADB_AUDIT_PLUGIN"
  #     option_settings = [
  #       {
  #         name  = "SERVER_AUDIT_EVENTS"
  #         value = "CONNECT"
  #       },
  #       {
  #         name  = "SERVER_AUDIT_FILE_ROTATIONS"
  #         value = "37"
  #       },
  #     ]
  #   },
  # ]
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