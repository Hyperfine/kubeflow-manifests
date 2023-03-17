# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA GLOBAL CLUSTER
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

provider "aws" {
  region = var.replica_region
  alias  = "replica"
}

# ------------------------------------------------------------------------------
# LAUNCH AURORA GLOBAL CLUSTER ON RDS
# ------------------------------------------------------------------------------

resource "aws_rds_global_cluster" "global_cluster" {
  global_cluster_identifier = "global-${var.name}"

  database_name = "mydb"

  engine              = var.engine
  engine_version      = var.engine_version
  storage_encrypted   = var.storage_encrypted
  deletion_protection = var.deletion_protection
}

module "aurora_global_cluster_primary" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  global_cluster_identifier = aws_rds_global_cluster.global_cluster.id

  name                = "${var.name}-1"
  port                = var.port
  engine              = var.engine
  engine_mode         = var.engine_mode
  engine_version      = var.engine_version
  instance_type       = var.instance_type
  instance_count      = var.instance_count
  master_username     = var.master_username
  master_password     = var.master_password
  storage_encrypted   = var.storage_encrypted
  kms_key_arn         = module.kms_master_key.key_arn[var.name]
  skip_final_snapshot = true # don't leave a final snapshot when testing the example

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # NOTE: To make testing easier, we make the cluster publicly accessible but in production, you will want to make sure
  # the database is only accessible from within the VPC.
  publicly_accessible                = true
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]
}

module "aurora_replica" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  providers = {
    aws = aws.replica
  }

  name                = var.name
  port                = var.port
  engine              = var.engine
  engine_mode         = var.engine_mode
  engine_version      = var.engine_version
  storage_encrypted   = var.storage_encrypted
  kms_key_arn         = module.kms_master_key_replica.key_arn[var.name]
  skip_final_snapshot = true

  global_cluster_identifier     = aws_rds_global_cluster.global_cluster.id
  replication_source_identifier = module.aurora_global_cluster_primary.cluster_arn
  source_region                 = var.aws_region

  instance_count = var.replica_count
  instance_type  = var.instance_type

  vpc_id     = data.aws_vpc.replica.id
  subnet_ids = data.aws_subnet_ids.replica.ids

  # NOTE: To make testing easier, we make the cluster publicly accessible but in production, you will want to make sure
  # the database is only accessible from within the VPC.
  publicly_accessible                = true
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  dependencies = [module.aurora_global_cluster_primary.instance_endpoints[0]]
}

module "kms_master_key_replica" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=v0.55.1"

  providers = {
    aws = aws.replica
  }

  customer_master_keys = {
    (var.name) = {
      deletion_window_in_days    = 7
      cmk_administrator_iam_arns = var.cmk_administrator_iam_arns
      cmk_user_iam_arns          = var.cmk_user_iam_arns
      cmk_service_principals     = []
    }
  }
}

module "kms_master_key" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=v0.55.1"

  customer_master_keys = {
    (var.name) = {
      deletion_window_in_days    = 7
      cmk_administrator_iam_arns = var.cmk_administrator_iam_arns
      cmk_user_iam_arns          = var.cmk_user_iam_arns
      cmk_service_principals     = []
    }
  }
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

data "aws_vpc" "replica" {
  provider = aws.replica
  default  = true
}

data "aws_subnet_ids" "replica" {
  provider = aws.replica
  vpc_id   = data.aws_vpc.replica.id
}
