provider "alicloud" {
  region     = "cn-shenzhen"
}

module "ecs_sg" {
  source                        = "../../modules/security_group/ecs_sg"
  env                           = "prod"  
  ecs_sg_name                   = "admin-center"
  vpc_id                        = "vpc-wz99nnhv5r99r7qescc78"
  inbound_rules = {
    "0" = [ "tcp","443/443","0.0.0.0/0" ]
    "1" = [ "tcp","80/80","0.0.0.0/0" ] 
    "2" = [ "tcp","22/22","0.0.0.0/0" ]    
  }
  outbound_rules = {
    "0" = [ "all","-1/-1","0.0.0.0/0" ]
  }  
}

module "slb" {
  source                        = "../../modules/slb/slb_tcp"
  env                           = "prod"
  slb_name                      = "admin-center"
  vswitch_id                    = "vsw-wz9ckx6hxzu2gl8p4s5zn"
  master_zone_id                = "cn-shenzhen-a"
  slave_zone_id                 = "cn-shenzhen-b"
  internet                      = true
}

module "ess" {
  source                        = "../../modules/ess"
  env                           = "prod"
  scaling_group_name            = "admin-center"
  instance_name                 = "admin-center"
  instance_type                 = "ecs.n1.tiny"
  image_id                      = "m-wz9c0rnhno787wc9s5mf"
  system_disk_size              = "100"
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
    "playbooks/prod/site-admin-center.yml",
  ]
}