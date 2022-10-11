terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = ">= 4"
  }

  backend "s3" {
    bucket = "state-versioning"
    key    = "terraform-curso-ambiente.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]
  region                   = "us-east-1"
}

module "ec2" {
  source    = "git@github.com:oproprioschelp/terraform-aws-ec2.git"
  int_type  = "t3.micro"
  int_name  = "WEB"
  user_data = file("./files/userdata.sh")
  ami       = "ami-05fa00d4c63e32376"
  subnet    = module.vpc.public_subnets
}

module "vpc" {
  source    = "git@github.com:oproprioschelp/terraform-aws-vpc.git"
  vpc_name  = "dev"
  vpc_cidr  = "172.32.0.0/16"
  nat_count = 2
}

module "rds" {
  source               = "git@github.com:oproprioschelp/terraform-aws-rds.git"
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "schelp"
  password             = "gotf"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet            = aws_db_subnet_group.default.id
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  tags = {
    Name = "My DB subnet group"
  }
}
