# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A STANDALONE APPLICATION LOAD BALANCER (ALB)
# These templates show an example of how to deploy a standalone ALB. In practice, you would usually define an ANB in
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
# CREATE AN ALB
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/alb?ref=v1.0.8"
  source = "../../modules/alb"

  aws_account_id = data.aws_caller_identity.current.id
  aws_region     = var.aws_region

  alb_name         = var.alb_name
  is_internal_alb  = false

  http_listener_ports = [80, 443]
  ssl_policy          = "ELBSecurityPolicy-TLS-1-1-2017-01"

  # Sample usage for HTTPS:
  # https_listener_ports_and_acm_ssl_certs = [
  #   {
  #     port = 443
  #     tls_domain_name = "*.foo.com"
  #   }
  # ]

  vpc_id                         = data.aws_vpc.default.id
  vpc_subnet_ids                 = data.aws_subnet_ids.default.ids
  enable_alb_access_logs         = true
  alb_access_logs_s3_bucket_name = module.alb_access_logs_bucket.s3_bucket_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET USED TO STORE THE ALB'S LOGS
# ---------------------------------------------------------------------------------------------------------------------

# Create an S3 Bucket to store ALB access logs.
module "alb_access_logs_bucket" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=upgrade-terraform12"

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region

  # Try to do some basic cleanup to get a valid S3 bucket name: the name must be lower case and can only contain
  # lowercase letters, numbers, and hyphens. For the full rules, see:
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  s3_bucket_name = "alb-${lower(replace(var.alb_name, "_", "-"))}-access-logs"

  s3_logging_prefix = var.alb_name

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
