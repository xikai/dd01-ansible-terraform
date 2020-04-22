resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr_block}"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    "Name"        = "${var.env}-${var.vpc_name}-vpc"
    "Project"     = "${var.vpc_name}"
    "Environment" = "${var.env}"  
    "kubernetes.io/cluster/dd01-eks" = "shared"  
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    "Name" = "${var.env}-${var.internet_gateway_name}-igw"
    "Project"     = "${var.internet_gateway_name}"
    "Environment" = "${var.env}"      
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
  # tags {
  #   "Name" = "${var.env}-${var.route_name}-route"
  #   "Project"     = "${var.route_name}"
  #   "Environment" = "${var.env}"      
  # }
}


data "aws_availability_zones" "available" {}


resource "aws_subnet" "default" {
   count                   = "${length(var.cidr_blocks)}"
   vpc_id                  = "${aws_vpc.default.id}"
   availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
   cidr_block              = "${var.cidr_blocks[count.index]}"
   map_public_ip_on_launch = true

   tags {
     "Name" = "${var.env}-${var.subnet_name}-${data.aws_availability_zones.available.names[count.index]}"
     "Environment" = "${var.env}"   
     "kubernetes.io/cluster/dd01-eks"  = "shared"
     "kubernetes.io/role/internal-elb" = "1"
   }
}   