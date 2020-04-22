provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "dd01-terraform-remote-state-storage-s3"
    dynamodb_table = "dd01-terraform-state-lock-dynamo"
    region         = "ap-southeast-1"
    key            = "prod/service/eks"
  }
}

module "eks_iam" {
  source                        = "../../modules/eks/eks-cluster-iam-role"
  eks_cluster_iam_name          = "eksServerRole"
}
module "eks_vpc" {
  source                        = "../../modules/eks/vpc"

  env                           = "dd01"
  subnet_name                   = "eks"
  vpc_name                      = "eks"   
  internet_gateway_name         = "eks"
  route_name                    = "eks"
  vpc_cidr_block                = "10.100.0.0/16"
  cidr_blocks                   = ["10.100.128.0/24", "10.100.129.0/24","10.100.130.0/24"]
}
