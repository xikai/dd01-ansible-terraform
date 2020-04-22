
variable "rds_family" {
  default = "mysql5.7"
}

variable "create" {
  description = "Whether to create this resource or not?"
  default     = true
}

variable "rds_parameters" {
  type        = "list"
  description = "A list of parameters to apply."
  default     = []    
}



variable "rds_allocated_storage" {
  type        = "string"
  default     = "30"
}

variable "rds_storage_type" {
  type        = "string"
  default     = "gp2"
}

variable "rds_iops" {
  type        = "string"
  default     = "0"
}

variable "rds_engine" {
  type        = "string"
  default     = "mysql"
}

variable "rds_engine_version" {
  type        = "string"
  default     = "5.7.17"
}

variable "rds_instance_class" {
  type        = "string"
  default     = "db.t2.micro"
}

variable "rds_identifier" {
  type        = "string"
}


variable "rds_username" {
  type        = "string"
  default     = "superadmin"
}

variable "rds_password_payload" {
  type        = "string"
}



variable "rds_subnet_ids" {
  type        = "list"
  description = "A list of VPC subnet IDs"
  default     = []
}


variable "rds_backup_retention_period" {
  type        = "string"
  default     = "7"
}

variable "rds_backup_window" {
  type        = "string"
  default     = "03:00-06:30"
}

variable "rds_skip_final_snapshot" {
  default     = false
}

variable "rds_multi_az" {
  default     = false
}

variable "rds_maintenance_window" {
  type        = "string"
  default     = "Sun:00:00-Sun:02:30"
}

variable "rds_vpc_security_group_ids" {
  type        = "string"
}

variable "rds_publicly_accessible" {
  default     = true
}
variable "rds_apply_immediately" {
  default = false
}

variable "env" {
  description = "env to deploy into, should typically dev/staging/prod"
}
variable "tags" {
  description = "A mapping of tags to assign to all resources"
  default     = {}
}

variable "rds_option_group_description" {
  description = "The description of the option group"
  default     = ""
}
variable "rds_major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  default     = ""  
}
variable "rds_options" {
  type        = "list"
  description = "A list of Options to apply."
  default     = []    
}
variable "rds_db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC"
  default     = ""
}

variable "rds_parameter_group_name" {
  description = "Name of the DB parameter group to associate. Setting this automatically disables parameter_group creation"
  default     = ""
}

variable "rds_option_group_name" {
  description = "Name of the DB option group to associate. Setting this automatically disables option_group creation"
  default     = ""
}
variable "rds_create_db_subnet_group" {
  description = "Whether to create a database subnet group"
  default     = true
}

variable "rds_create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  default     = true
}

variable "rds_create_db_option_group" {
  description = "Whether to create a database option group"
  default     = true
}