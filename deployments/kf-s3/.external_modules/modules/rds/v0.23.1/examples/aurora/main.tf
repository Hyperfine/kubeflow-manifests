# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA
# This template shows an example of how to use the aurora module to launch an
# RDS cluster with Amazon Aurora. The cluster is managed by AWS and automatically
# handles leader election, replication, failover, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# LAUNCH AURORA ON RDS
# ------------------------------------------------------------------------------

module "aurora_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  name                = "${var.name}-1"
  master_username     = var.master_username
  master_password     = var.master_password
  engine_mode         = var.engine_mode
  storage_encrypted   = var.storage_encrypted
  apply_immediately   = var.apply_immediately
  skip_final_snapshot = true

  instance_count = var.instance_count
  instance_type  = var.instance_type

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  create_subnet_group      = var.create_subnet_group
  aws_db_subnet_group_name = var.aws_db_subnet_group_name
}

module "aurora_2" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  name                = "${var.name}-2"
  db_name             = "mydb"
  master_username     = var.master_username
  master_password     = var.master_password
  engine_mode         = var.engine_mode
  storage_encrypted   = var.storage_encrypted
  apply_immediately   = var.apply_immediately
  skip_final_snapshot = true

  instance_count = var.instance_count
  instance_type  = var.instance_type

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  create_subnet_group      = var.create_subnet_group
  aws_db_subnet_group_name = var.aws_db_subnet_group_name
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means the DB is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
