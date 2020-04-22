locals {
  db_subnet_group_name          = "${coalesce(var.rds_db_subnet_group_name, module.db_subnet_group.this_db_subnet_group_id)}"
  enable_create_db_subnet_group = "${var.rds_db_subnet_group_name == "" ? var.rds_create_db_subnet_group : 0}"

  parameter_group_name             = "${coalesce(var.rds_parameter_group_name, module.db_parameter_group.this_db_parameter_group_id)}"
  enable_create_db_parameter_group = "${var.rds_parameter_group_name == "" ? var.rds_create_db_parameter_group : 0}"

  option_group_name             = "${coalesce(var.rds_option_group_name, module.db_option_group.this_db_option_group_id)}"
  enable_create_db_option_group = "${var.rds_option_group_name == "" && var.rds_engine != "postgres" ? var.rds_create_db_option_group : 0}"
}

module "db_subnet_group" {
  source = "./db_subnet_group"

  create      = "${local.enable_create_db_subnet_group}"
  identifier  = "${var.env}-${var.rds_identifier}"
  name_prefix = "${var.env}-${var.rds_identifier}-"
  subnet_ids  = ["${var.rds_subnet_ids}"]

  tags = "${var.tags}"
}

module "db_parameter_group" {
  source = "./db_parameter_group"

  create      = "${local.enable_create_db_parameter_group}"
  identifier  = "${var.env}-${var.rds_identifier}"
  name_prefix = "${var.env}-${var.rds_identifier}-"
  family      = "${var.rds_family}"

  parameters = ["${var.rds_parameters}"]

  tags = "${var.tags}"
}

module "db_option_group" {
  source = "./db_option_group"

  create                   = "${local.enable_create_db_option_group}"
  identifier               = "${var.env}-${var.rds_identifier}"
  name_prefix              = "${var.env}-${var.rds_identifier}-"
  option_group_description = "${var.rds_option_group_description}"
  engine_name              = "${var.rds_engine}"
  major_engine_version     = "${var.rds_major_engine_version}"

  options = ["${var.rds_options}"]

  tags = "${var.tags}"
}

data "aws_kms_secrets" "db" {
  secret {
    name    = "master_password"
    payload = "${var.rds_password_payload}"

    context {
      team = "devops"
    }
  }
}

resource "aws_db_instance" "rds_conf" {
    allocated_storage           = "${var.rds_allocated_storage}"
    storage_type                = "${var.rds_storage_type}"
    iops                        = "${var.rds_iops}"
    engine                      = "${var.rds_engine}"
    engine_version              = "${var.rds_engine_version}"
    instance_class              = "${var.rds_instance_class}"
    identifier                  = "${var.env}-${var.rds_identifier}" # RDS instance name
    username                    = "${var.rds_username}"
    password                    = "${data.aws_kms_secrets.db.plaintext["master_password"]}"
    parameter_group_name        = "${local.parameter_group_name}"
    db_subnet_group_name        = "${local.db_subnet_group_name}"
    option_group_name           = "${local.option_group_name}"
    final_snapshot_identifier   = "last-${var.rds_identifier}"  #最后一次快照名称
    skip_final_snapshot         = "${var.rds_skip_final_snapshot}" #是否跳过最后一次快照
    backup_retention_period     = "${var.rds_backup_retention_period}"
    backup_window               = "${var.rds_backup_window}"
    multi_az                    = "${var.rds_multi_az}"
    vpc_security_group_ids      = ["${var.rds_vpc_security_group_ids}"]
    publicly_accessible         = "${var.rds_publicly_accessible}"
    apply_immediately           = "${var.rds_apply_immediately}"
    allow_major_version_upgrade = "false"   #自动主要版本升级
    auto_minor_version_upgrade  = "false"   #自动将要版本升级
    maintenance_window          = "${var.rds_maintenance_window}"
    tags {
        Name = "${var.env}-${var.rds_identifier}-rds"
        Billing = "${var.env}"
        Team = "${var.billing_team}"
  }
}
