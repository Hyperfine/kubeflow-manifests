# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A STANDALONE NETWORK LOAD BALANCER (NLB)
# These templates show an example of how to deploy a standalone ANB. In practice, you would usually define an ANB in
# conjunction with an ECS Cluster, ECS Service, and/or Auto Scaling Group.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN NLB
# ---------------------------------------------------------------------------------------------------------------------

module "nlb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/nlb?ref=v1.0.0"
  source = "../../modules/nlb"

  aws_region = var.aws_region

  nlb_name         = var.nlb_name
  environment_name = var.environment_name
  is_internal_nlb  = false

  tcp_listener_ports = [80, 8080]

  vpc_id                         = data.aws_vpc.default.id
  vpc_subnet_ids                 = data.aws_subnet_ids.default.ids
  enable_nlb_access_logs         = true
  nlb_access_logs_s3_bucket_name = module.nlb_access_logs_bucket.s3_bucket_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET USED TO STORE THE NLB'S LOGS
# ---------------------------------------------------------------------------------------------------------------------

# Create an S3 Bucket to store NLB access logs.
module "nlb_access_logs_bucket" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=upgrade-terraform12"

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region

  # Try to do some basic cleanup to get a valid S3 bucket name: the name must be lower case and can only contain
  # lowercase letters, numbers, and hyphens. For the full rules, see:
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  s3_bucket_name = "nlb-${lower(replace(var.nlb_name, "_", "-"))}-access-logs"

  s3_logging_prefix = var.nlb_name

  num_days_after_which_archive_log_data = var.num_days_after_which_archive_log_data
  num_days_after_which_delete_log_data  = var.num_days_after_which_delete_log_data

  ## DO NOT USE THIS SETTING IN PRODUCTION! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
  # In a test environment, we want to destroy the S3 Bucket, even if data is there when we do so. But in production, the
  # default setting of preventing a non-empty S3 Bucket from being destroyed should be used. Therefore, this property can
  # be omitted in production use.
  force_destroy = var.force_destroy_access_logs_s3_bucket
  ## DO NOT USE THIS SETTING IN PRODUCTION! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
