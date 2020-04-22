provider "alicloud" {
  region     = "cn-shenzhen"
}

module "ecs_sg" {
  source                        = "../../modules/security_group/ecs_sg"
  env                           = "qa"  
  ecs_sg_name                   = "xikai-test"
  vpc_id                        = "vpc-wz931xhagnps46jbjycdh"
  inbound_rules = {
    "0" = [ "tcp","443/443","0.0.0.0/0" ]
    "1" = [ "tcp","22/22","0.0.0.0/0" ]    
  }
  outbound_rules = {
    "0" = [ "all","-1/-1","0.0.0.0/0" ]
  }  
}

module "ecs" {
  source                        = "../../modules/ecs"
  env                           = "qa"
  instance_name                 = "xikai-test"
  instance_type                 = "ecs.sn1ne.large"
  system_disk_category          = "cloud_efficiency"
  image_id                      = "m-wz9bptxbwn7fnazri3ur"
  availability_zone             = "cn-shenzhen-a"
  vswitch_id                    = "vsw-wz9v3gmfber5d74646pew"
  security_groups               = ["${module.ecs_sg.ecs_sg_id}"]
  internet_max_bandwidth_out    = "5"
  instance_charge_type          = "PrePaid"
  password                      = "Xikai0test"
}

module "slb" {
  source                        = "../../modules/slb"
  env                           = "qa"
  slb_name                      = "xikai-test"
  vswitch_id                    = "vsw-wz9v3gmfber5d74646pew"
  master_zone_id                = "cn-shenzhen-a"
  slave_zone_id                 = ""
  internet                      = true
  health_check_uri              = "/health_check"
  health_check_http_code        = "http_2xx,http_3xx"
}

module "ess" {
  source                        = "../../modules/ess"
  env                           = "qa"
  scaling_group_name            = "xikai-test"
  instance_name                 = "xikai-test"
  instance_type                 = "ecs.sn1ne.large"
  image_id                      = "m-wz9baijz5z0iju0xcj5w"
  system_disk_size              = "100"
  system_disk_category          = "cloud_ssd"
  security_group_id             = "${module.ecs_sg.ecs_sg_id}"
  min_size                      = "1"
  max_size                      = "1"
  adjustment_type               = "TotalCapacity"
  adjustment_value              = "2"
  key_name                      = "ali-ecs"
  role_name                     = "ansible-oss-pull"
  vswitch_ids                   = ["vsw-wz9v3gmfber5d74646pew","vsw-wz99yw85f8xx06fl2ho1m"]
  loadbalancer_ids              = ["${module.slb.slb_id}"]
  db_instance_ids               = ["${module.rds.rds_id}"]
  multi_az_policy               = "BALANCE"

  userdata_ENV_HOME             = "/root"
  userdata_OSS_ANSIBLE          = "dd01-devops-ansible"
  userdata_VAR_PLAYBOOKS        = [
    "playbooks/common/load-sshkey.yml",
    "playbooks/common/sysctl.yml",
    "playbooks/site-demo.yml",
  ]
}

module "rds" {
  source                        = "../../modules/rds"
  env                           = "qa"
  engine                        = "MySQL"
  engine_version                = "5.7"
  instance_name                 = "xikai-test"
  instance_type                 = "rds.mysql.t1.small"
  instance_storage              = "10"
  zone_id                       = "cn-shenzhen-c"         #创建高可用版多可用区实例时，注释这项 使用alicloud_zones.
  vswitch_id                    = "vsw-wz9s0km2hf3s715myu5qu"

  database_name                 = "xikai-test"
  character_set                 = "utf8"
  username                      = "dadi01"
  password                      = "dd01db"
}

module "redis" {
  source                        = "../../modules/redis"
  env                           = "qa"
  instance_name                 = "xikai-test"
  engine                        = "Redis"
  engine_version                = "4.0"
  instance_class                = "redis.master.small.default"           
  password                      = "Xikai0test"
  #availability_zone             = "cn-shenzhen-a"
  vswitch_id                    = "vsw-wz9v3gmfber5d74646pew"
  security_ips                  = ["172.18.0.0/16"]
}

module "mongodb" {
  source                        = "../../modules/mongo_replica"
  env                           = "qa"
  name                          = "xikai-test"
  engine_version                = "3.4"
  db_instance_class             = "dds.mongo.mid"
  db_instance_storage           = 10
  #zone_id                       = "cn-shenzhen-a"
  vswitch_id                    = "vsw-wz9v3gmfber5d74646pew"
  account_password              = "Xikai0test"
  security_ip_list              = ["172.18.0.0/16"]
}