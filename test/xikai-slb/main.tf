module "slb" {
  source                        = "../../modules/slb"
  env                           = "qa"
  slb_name                      = "xikai-slb-test"
  vswitch_id                    = "vsw-wz9ckx6hxzu2gl8p4s5zn"
  master_zone_id                = "cn-shenzhen-a"
  slave_zone_id                 = "cn-shenzhen-b"
  internet                      = false
}