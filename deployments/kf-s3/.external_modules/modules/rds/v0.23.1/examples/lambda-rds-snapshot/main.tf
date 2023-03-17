# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE TWO RDS DBS AND LAMBDA FUNCTIONS TO PERIODICALLY TAKE SNAPSHOTS OF THOSE DBS
# These lambda functions can also, optionally, a) trigger another lambda function to share the snapshot with another AWS
# account and b) report a metric to CloudWatch to indicate the backup completed successfully.
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
  instance_type = "db.t3.micro"

  allocated_storage       = 10
  multi_az                = false
  num_read_replicas       = 0
  backup_retention_period = 0
  skip_final_snapshot     = true
}

# ------------------------------------------------------------------------------
# LAUNCH AN AURORA DB
# ------------------------------------------------------------------------------

module "aurora" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  name            = "${var.name}-aurora"
  master_username = var.master_username
  master_password = var.master_password

  instance_count = 1
  instance_type  = "db.t3.medium"

  vpc_id                             = data.aws_vpc.default.id
  subnet_ids                         = data.aws_subnet_ids.default.ids
  allow_connections_from_cidr_blocks = var.allow_connections_from_cidr_blocks
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO TAKE PERIODIC SNAPSHOTS OF THE MYSQL DB
# ------------------------------------------------------------------------------

module "mysql_create_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-create-snapshot"
  create_resources = var.enable_snapshot

  # Note that in production usage, if you have read replicas, you may want to take snapshots of the replicas instead
  # so as not to put additional load on the primary
  rds_db_identifier = module.mysql.primary_id

  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  schedule_expression = var.schedule_expression

  report_cloudwatch_metric           = true
  report_cloudwatch_metric_namespace = "custom/rds"
  report_cloudwatch_metric_name      = "example-mysql-backup"

  # Automatically share the snapshots with the AWS account in var.share_snapshots_with_account_id
  share_snapshot_with_another_account = true
  share_snapshot_lambda_arn           = module.mysql_share_snapshot.lambda_function_arn
  share_snapshot_with_account_id      = var.external_account_id
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO TAKE PERIODIC SNAPSHOTS OF THE AURORA DB
# ------------------------------------------------------------------------------

module "aurora_create_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-create-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-create-snapshot"
  create_resources = var.enable_snapshot

  # Note that in production usage, if you have read replicas, you may want to take snapshots of the replicas instead
  # so as not to put additional load on the primary
  rds_db_identifier = module.aurora.cluster_id

  rds_db_arn               = module.aurora.cluster_arn
  rds_db_is_aurora_cluster = true

  schedule_expression = var.schedule_expression

  # Automatically share the snapshots with the AWS account in var.share_snapshots_with_account_id
  share_snapshot_with_another_account = true
  share_snapshot_lambda_arn           = module.aurora_share_snapshot.lambda_function_arn
  share_snapshot_with_account_id      = var.external_account_id
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO SHARE THE MYSQL SNAPSHOTS WITH AN ANOTHER AWS ACCOUNT
# ------------------------------------------------------------------------------

module "mysql_share_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-share-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-share-snapshot"
  create_resources = var.enable_snapshot

  rds_db_arn = module.mysql.primary_arn
  name       = "${var.name}-share-mysql"
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO SHARE THE AURORA SNAPSHOTS WITH AN ANOTHER AWS ACCOUNT
# ------------------------------------------------------------------------------

module "aurora_share_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-share-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-share-snapshot"
  create_resources = var.enable_snapshot

  rds_db_arn = module.aurora.cluster_arn
  name       = "${var.name}-share-aurora"
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO MAKE LOCAL COPIES OF MYSQL SNAPSHOTS FROM AN ANOTHER AWS ACCOUNT
# Normally, this code would run in a totally separate account, making copies of any snapshots that were shared.
# However, to keep this example simple, we are putting demonstrating how to use this code in one place.
# ------------------------------------------------------------------------------

module "mysql_copy_shared_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-copy-shared-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-copy-shared-snapshot"
  create_resources = var.enable_snapshot

  rds_db_identifier        = module.mysql.primary_id
  rds_db_is_aurora_cluster = false

  schedule_expression = var.schedule_expression
  external_account_id = var.external_account_id

  report_cloudwatch_metric           = true
  report_cloudwatch_metric_namespace = "custom/rds"
  report_cloudwatch_metric_name      = "example-mysql-local-copy"
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO MAKE LOCAL COPIES OF AURORA SNAPSHOTS FROM AN ANOTHER AWS ACCOUNT
# Normally, this code would run in a totally separate account, making copies of any snapshots that were shared.
# However, to keep this example simple, we are putting demonstrating how to use this code in one place.
# ------------------------------------------------------------------------------

module "aurora_copy_shared_snapshot" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-copy-shared-snapshot?ref=v1.0.8"
  source           = "../../modules/lambda-copy-shared-snapshot"
  create_resources = var.enable_snapshot

  rds_db_identifier        = module.aurora.cluster_id
  rds_db_is_aurora_cluster = true

  schedule_expression = var.schedule_expression
  external_account_id = var.external_account_id
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO DELETE OLD SNAPSHOTS OF THE MYSQL DB
# ------------------------------------------------------------------------------

module "mysql_cleanup_snapshots" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-cleanup-snapshots?ref=v1.0.8"
  source           = "../../modules/lambda-cleanup-snapshots"
  create_resources = var.enable_snapshot

  rds_db_identifier        = module.mysql.primary_id
  rds_db_arn               = module.mysql.primary_arn
  rds_db_is_aurora_cluster = false

  schedule_expression = var.schedule_expression
  max_snapshots       = var.max_snapshots
  allow_delete_all    = var.allow_delete_all
}

# ------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO DELETE OLD SNAPSHOTS OF THE AURORA DB
# ------------------------------------------------------------------------------

module "aurora_cleanup_snapshots" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-cleanup-snapshots?ref=v1.0.8"
  source           = "../../modules/lambda-cleanup-snapshots"
  create_resources = var.enable_snapshot

  rds_db_identifier        = module.aurora.cluster_id
  rds_db_arn               = module.aurora.cluster_arn
  rds_db_is_aurora_cluster = true

  schedule_expression = var.schedule_expression
  max_snapshots       = var.max_snapshots
  allow_delete_all    = var.allow_delete_all
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
