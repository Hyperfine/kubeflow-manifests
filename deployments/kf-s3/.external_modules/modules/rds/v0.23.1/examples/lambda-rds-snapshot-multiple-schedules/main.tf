# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN RDS DB AND LAMBDA FUNCTIONS TO PERIODICALLY TAKE SNAPSHOTS OF THOSE DBS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# LAUNCH A MYSQL DB
# ------------------------------------------------------------------------------

module "mysql" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/rds?ref=v1.0.8"
  source = "../../modules/rds"

  name           = "${var.name}-mysql"
  engine         = "mysql"
  engine_version = "8.0.27"
  port           = 3306

  master_username = var.master_username
  master_password = var.master_password

  vpc_id                             = data.aws_vpc.default.id
  subnet_ids                         = data.aws_subnet_ids.default.ids
  allow_connections_from_cidr_blocks = var.allow_connections_from_cidr_blocks

  # Since this is just an example, we are using a small DB instance with only 10GB of storage, no standby, no replicas,
  # and no automatic backups. You'll want to tweak all of these settings for production usage.
  instance_type = "db.t2.small"

  allocated_storage       = 10
  multi_az                = false
  num_read_replicas       = 0
  backup_retention_period = 0
  skip_final_snapshot     = true
  # db.t2.micro instances do not support encryption
  storage_encrypted = false
}

# ------------------------------------------------------------------------------
# CREATE LAMBDA FUNCTIONS TO TAKE HOURLY AND WEEKLY SNAPSHOTS OF THE DB
# ------------------------------------------------------------------------------

module "create_hourly_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"
  source = "../../modules/lambda-create-snapshot"

  # Note that in production usage, if you have read replicas, you may want to take snapshots of the replicas instead
  # so as not to put additional load on the primary
  rds_db_identifier = module.mysql.primary_id

  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  lambda_namespace    = "${var.name}-create-hourly-snapshot"
  snapshot_namespace  = "hourly"
  schedule_expression = "rate(1 hour)"

  report_cloudwatch_metric           = true
  report_cloudwatch_metric_namespace = "custom/rds"
  report_cloudwatch_metric_name      = "example-mysql-hourly-backup"
}

module "create_weekly_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"
  source = "../../modules/lambda-create-snapshot"

  # Note that in production usage, if you have read replicas, you may want to take snapshots of the replicas instead
  # so as not to put additional load on the primary
  rds_db_identifier = module.mysql.primary_id

  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  lambda_namespace    = "${var.name}-create-weekly-snapshot"
  snapshot_namespace  = "weekly"
  schedule_expression = "rate(7 days)"

  report_cloudwatch_metric           = true
  report_cloudwatch_metric_namespace = "custom/rds"
  report_cloudwatch_metric_name      = "example-mysql-weekly-backup"
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO DELETE OLD SNAPSHOTS OF THE MYSQL DB
# Keep hourly snapshots for three days, and weekly snapshots for six months,
# showing how these retention periods can differ with the snapshot namespace.
# ------------------------------------------------------------------------------

module "cleanup_hourly_snapshots" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-cleanup-snapshots?ref=v1.0.8"
  source = "../../modules/lambda-cleanup-snapshots"

  rds_db_identifier        = module.mysql.primary_id
  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  lambda_namespace    = "${var.name}-delete-hourly-snapshots"
  snapshot_namespace  = "hourly"
  schedule_expression = "rate(1 hour)"

  max_snapshots    = var.max_hourly_snapshots
  allow_delete_all = var.allow_delete_all
}

module "cleanup_weekly_snapshots" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-cleanup-snapshots?ref=v1.0.8"
  source = "../../modules/lambda-cleanup-snapshots"

  rds_db_identifier        = module.mysql.primary_id
  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  lambda_namespace    = "${var.name}-delete-weekly-snapshots"
  snapshot_namespace  = "weekly"
  schedule_expression = "rate(7 days)"

  max_snapshots    = var.max_weekly_snapshots
  allow_delete_all = var.allow_delete_all
}

# ------------------------------------------------------------------------------
# DEPLOY THESE EXAMPLES INTO THE DEFAULT VPC AND SUBNETS
# In production usage, you should instead use a custom VPC and private subnets
# ------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
