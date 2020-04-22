provider "alicloud" {
  region     = "cn-shenzhen"
}

module "ecs_sg" {
  source                        = "../../modules/security_group/ecs_sg"
  env                           = "prod"  
  ecs_sg_name                   = "apiserver02"
  vpc_id                        = "vpc-wz99nnhv5r99r7qescc78"
  inbound_rules = {
    "0" = [ "tcp","443/443","0.0.0.0/0" ]
    "1" = [ "tcp","80/80","0.0.0.0/0" ] 
    "2" = [ "tcp","22/22","0.0.0.0/0" ]
    "3" = [ "tcp","10050/10050","172.19.0.0/16" ]    
  }
  outbound_rules = {
    "0" = [ "all","-1/-1","0.0.0.0/0" ]
  }  
}

module "slb" {
  source                        = "../../modules/slb/slb_tcp"
  env                           = "prod"
  slb_name                      = "apiserver02"
  vswitch_id                    = "vsw-wz9ckx6hxzu2gl8p4s5zn"
  master_zone_id                = "cn-shenzhen-a"
  slave_zone_id                 = "cn-shenzhen-b"
}

module "eip" {
  source                        = "../../modules/eip"
  env                           = "prod"
  eip_name                      = "apiserver02"  
  bandwidth                     = "50"
  internet_charge_type          = "PayByTraffic"
  instance_id                   = "${module.slb.slb_id}"
}

module "ess" {
  source                        = "../../modules/ess"
  env                           = "prod"
  scaling_group_name            = "apiserver02"
  instance_name                 = "apiserver02"
  instance_type                 = "ecs.sn1ne.xlarge"
  image_id                      = "m-wz92o83jsu6wyuuh9l0w"
  system_disk_size              = "300"
  system_disk_category          = "cloud_ssd"
  security_group_id             = "${module.ecs_sg.ecs_sg_id}"
  min_size                      = "2"
  max_size                      = "4"
  adjustment_type               = "TotalCapacity"
  adjustment_value              = "4"
  key_name                      = "ali-fncul"
  role_name                     = "ansible-oss-pull"
  vswitch_ids                   = ["vsw-wz9ckx6hxzu2gl8p4s5zn","vsw-wz9wdokaz2iwwff5127w1"]
  loadbalancer_ids              = ["${module.slb.slb_id}"]
  db_instance_ids               = ["rm-wz9c51214vulbfjtm"]
  multi_az_policy               = "BALANCE"
  
  userdata_CODE_SERVER          = "172.19.27.202:82"
  userdata_ENV_HOME             = "/root"
  userdata_OSS_ANSIBLE          = "dd01fn-devops-ansible"
  userdata_VAR_PLAYBOOKS        = [
    "playbooks/common/load-sshkey.yml",
    "playbooks/common/sysctl.yml",
    "playbooks/site-prod-apiserver02.yml",
  ]
}