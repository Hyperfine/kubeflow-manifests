# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN S3 BUCKET TO STORE ELB & ALB ACCESS LOGS
# This also includes a policy that gives the ELB/ALB permissions to write to the S3 bucket and a lifecycle rule to
# archive and/or delete log files over time.
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

# ----------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET WHERE ELB/ALB LOGS WILL BE STORED
# ----------------------------------------------------------------------------------------------------------------------

module "access_logs" {
  source           = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/private-s3-bucket?ref=v0.60.0"
  create_resources = var.create_resources

  name              = var.s3_bucket_name
  force_destroy     = var.force_destroy
  tags              = var.tags
  enable_versioning = true
  sse_algorithm     = "AES256" # For access logging buckets, only AES256 encryption is supported

  access_logging_enabled = var.enable_s3_server_access_logging
  access_logging_bucket = (
    local.should_create_access_log_bucket
    ? module.s3_access_logging_bucket.name
    : var.s3_server_access_logging_bucket
  )
  access_logging_prefix = var.s3_server_access_logging_prefix

  object_lock_enabled                   = var.object_lock_enabled
  object_lock_default_retention_enabled = var.object_lock_default_retention_enabled
  object_lock_mode                      = var.object_lock_mode
  object_lock_days                      = var.object_lock_days
  object_lock_years                     = var.object_lock_years

  # The sole permission needed for this Bucket is the ability for the AWS ELB Service Account to write logs
  bucket_policy_statements = var.bucket_policy_statements != {} ? var.bucket_policy_statements : {
    EnableLoadBalancerToWriteLogs = {
      effect  = "Allow"
      actions = ["s3:PutObject"]
      keys    = ["/${local.log_bucket_key_prefix}/*"]
      principals = {
        AWS     = ["arn:aws:iam::${data.aws_elb_service_account.main.id}:root"]
        Service = ["delivery.logs.amazonaws.com"]
      }
    }
  }

  # lifecycle_rules only gets created if at least one of num_days_after_which_archive_log_data and
  # num_days_after_which_delete_log_data is not 0. The values of these two variables are then used in the block
  # to conditionally create specific aspects of lifecycle rules, e.g. `transition` only gets created if
  # num_days_after_which_archive_log_data is not 0, and `expiration` only gets created if num_days_after_which_delete_log_data
  # is not 0, etc.
  lifecycle_rules = (var.num_days_after_which_archive_log_data == 0 && var.num_days_after_which_delete_log_data == 0) ? {} : {
    (local.lifecycle_rule_id) = {
      enabled = true
      prefix  = local.log_bucket_key_prefix

      abort_incomplete_multipart_upload_days = (
        var.num_days_after_which_archive_log_data != 0
        ? var.num_days_after_which_archive_log_data
        : var.num_days_after_which_delete_log_data
      )

      # This translates to a for_each on the transition subblock of the s3 bucket, so we set the value to empty list
      # to disable the block if we don't want to archive the objects.
      transition = (
        var.num_days_after_which_archive_log_data != 0
        ? [{
          storage_class = "GLACIER"
          days          = var.num_days_after_which_archive_log_data
        }]
        : []
      )

      # This translates to a for_each on the expiration subblock of the s3 bucket, so we set the value to empty list
      # to disable the block if we don't want objects to be deleted.
      expiration = (
        var.num_days_after_which_delete_log_data != 0
        ? [{
          days = var.num_days_after_which_delete_log_data
        }]
        : []
      )

      # We enable this to permanently delete the object on expiration if we want data to be deleted after a number
      # of days.
      noncurrent_version_expiration = (
        var.num_days_after_which_delete_log_data != 0
        ? var.num_days_after_which_delete_log_data
        : null
      )
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET THAT STORES ACCESS LOGS
# ----------------------------------------------------------------------------------------------------------------------

locals {
  should_create_access_log_bucket = var.enable_s3_server_access_logging && var.s3_server_access_logging_bucket == null
}

# (optionally) Create a separate bucket where server access logs will be stored
module "s3_access_logging_bucket" {
  source           = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/private-s3-bucket?ref=v0.60.0"
  create_resources = local.should_create_access_log_bucket

  name          = "${var.s3_bucket_name}-access-logs"
  acl           = "log-delivery-write"
  sse_algorithm = "AES256" # For access logging buckets, only AES256 encryption is supported
  force_destroy = var.s3_server_access_logging_bucket_force_destroy

  object_lock_enabled                   = var.s3_server_access_logging_bucket_object_lock_enabled
  object_lock_default_retention_enabled = var.s3_server_access_logging_bucket_object_lock_default_retention_enabled
  object_lock_mode                      = var.s3_server_access_logging_bucket_object_lock_mode
  object_lock_days                      = var.s3_server_access_logging_bucket_object_lock_days
  object_lock_years                     = var.s3_server_access_logging_bucket_object_lock_years

}

# ----------------------------------------------------------------------------------------------------------------------
# LOCALS
# These are global constants used throughout the module
# ----------------------------------------------------------------------------------------------------------------------

locals {
  # Conditionally set the ID of the lifecycle rule, based on the values of num_days_after_which_archive_log_data
  # and num_days_after_which_delete_log_data. Namely:
  # if both of them are 0, we neither archive nor delete data
  # if only num_days_after_which_delete_log_data is 0, we only archive
  # if only num_days_after_which_archive_log_data is 0, we only delete
  # if neither are 0, we both archive and delete
  lifecycle_rule_id = (
    var.num_days_after_which_delete_log_data == 0 && var.num_days_after_which_archive_log_data == 0 ? "no-archive-or-delete"
    : (var.num_days_after_which_delete_log_data == 0 ? "auto-archive-after-${var.num_days_after_which_archive_log_data}-days"
      : (var.num_days_after_which_archive_log_data == 0 ? "auto-delete-after-${var.num_days_after_which_delete_log_data}-days"
  : "auto-archive-after-${var.num_days_after_which_archive_log_data}-days-and-delete-after-${var.num_days_after_which_delete_log_data}-days")))
  log_bucket_key_prefix = "${var.s3_logging_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# Per https://goo.gl/sIBJ4H, we need the AWS Account ID of the ELB Service Account to grant that account permission to
# write to our S3 Bucket used for the ELB/ALB's logs.
data "aws_elb_service_account" "main" {}
