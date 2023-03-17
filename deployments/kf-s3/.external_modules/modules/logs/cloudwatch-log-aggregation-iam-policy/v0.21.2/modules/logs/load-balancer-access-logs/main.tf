# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN S3 BUCKET TO STORE ELB & ALB ACCESS LOGS
# This also includes a policy that gives the ELB/ALB permissions to write to the S3 bucket and a lifecycle rule to
# archive and/or delete log files over time.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET WHERE ELB/ALB LOGS WILL BE STORED
# Unfortunately, Terraform does not allow conditional creation of inline resources like lifecycle_rule (https://goo.gl/tzJ7uu).
# Therefore, we must put the conditional logic in the "count" property and declare 4 possible S3 Buckets with the
# expectation that exactly 1 of them will be created.
#
# WARNING! Because of the above limitation, changes to var.num_days_after_which_archive_log_data or
# var.num_days_after_which_delete_log_data may cause Terraform to destroy and re-create your S3 Bucket. To avoid this,
# make use of "terraform import" functionality. Contact Gruntwork support if help is needed with this operation.
# ----------------------------------------------------------------------------------------------------------------------

# Create the S3 Bucket where S3 objects will be neither ARCHIVED nor DELETED.
# NOTE: This bucket will only be created if:
# - var.create_resources is true
# - var.num_days_after_which_archive_log_data == 0
# - var.num_days_after_which_delete_log_data == 0
resource "aws_s3_bucket" "access_logs" {
  count = var.create_resources && var.num_days_after_which_archive_log_data == 0 && var.num_days_after_which_delete_log_data == 0 ? 1 : 0

  bucket        = var.s3_bucket_name
  acl           = "private"
  policy        = local.s3_bucket_policy
  force_destroy = var.force_destroy
  tags          = var.tags

  # There will never be a legitimate reason to overwrite a log entry, but if it does happen, enable S3 Bucket versioning
  # to ensure that the the original log files remain untouched.
  versioning {
    enabled = true
  }
}

# Create the S3 Bucket where S3 objects will be ARCHIVED after X days. No delete will take place.
# NOTE: This bucket will only be created if:
# - var.create_resources is true
# - var.num_days_after_which_archive_log_data > 0
# - var.num_days_after_which_delete_log_data == 0
resource "aws_s3_bucket" "access_logs_with_logs_archived_only" {
  count = var.create_resources && var.num_days_after_which_archive_log_data > 0 && var.num_days_after_which_delete_log_data == 0 ? 1 : 0

  bucket        = var.s3_bucket_name
  acl           = "private"
  policy        = local.s3_bucket_policy
  force_destroy = var.force_destroy
  tags          = var.tags

  # There will never be a legitimate reason to overwrite a log entry, but if it does happen, enable S3 Bucket versioning
  # to ensure that the the original log files remain untouched.
  versioning {
    enabled = true
  }

  # Automatically archive a log file after X days and delete after Y days.
  lifecycle_rule {
    # The id is the name of the lifecycle rule in the AWS Web Console
    id                                     = "auto-archive-after-${var.num_days_after_which_archive_log_data}-days"
    prefix                                 = local.log_bucket_key_prefix
    enabled                                = true
    abort_incomplete_multipart_upload_days = var.num_days_after_which_archive_log_data

    # Transfer data from S3 to Glacier
    transition {
      days          = var.num_days_after_which_archive_log_data
      storage_class = "GLACIER"
    }
  }
}

# Create the S3 Bucket where S3 objects will be DELETED after X days. No archiving will take place
# NOTE: This bucket will only be created if:
# - var.create_resources is true
# - var.num_days_after_which_archive_log_data == 0
# - var.num_days_after_which_delete_log_data > 0
resource "aws_s3_bucket" "access_logs_with_logs_deleted_only" {
  count = var.create_resources && var.num_days_after_which_archive_log_data == 0 && var.num_days_after_which_delete_log_data > 0 ? 1 : 0

  bucket        = var.s3_bucket_name
  acl           = "private"
  policy        = local.s3_bucket_policy
  force_destroy = var.force_destroy
  tags          = var.tags

  # There will never be a legitimate reason to overwrite a log entry, but if it does happen, enable S3 Bucket versioning
  # to ensure that the the original log files remain untouched.
  versioning {
    enabled = true
  }

  # Automatically delete a log file after X days.
  lifecycle_rule {
    # The id is the name of the lifecycle rule in the AWS Web Console
    id                                     = "auto-delete-after-${var.num_days_after_which_delete_log_data}-days"
    prefix                                 = local.log_bucket_key_prefix
    enabled                                = true
    abort_incomplete_multipart_upload_days = var.num_days_after_which_delete_log_data

    # First an object becomes "expired". Given that we've enabled S3 versioning, this means the "current" object is
    # marked with a "delete marker" but still available as a "non-current" (previous) version. Note that if
    # var.num_days_after_which_delete_log_data == 0, then this will be a no-op.
    expiration {
      days = var.num_days_after_which_delete_log_data
    }

    # Permanently delete the object by expiring the "non-current" object.
    noncurrent_version_expiration {
      days = var.num_days_after_which_delete_log_data
    }
  }
}

# Create the S3 Bucket where S3 objects will be ARCHIVED after X days and DELETED after Y days.
# NOTE: This bucket will only be created if:
# - var.create_resources is true
# - var.num_days_after_which_archive_log_data > 0
# - var.num_days_after_which_delete_log_data > 0
resource "aws_s3_bucket" "access_logs_with_logs_archived_and_deleted" {
  count = var.create_resources && var.num_days_after_which_archive_log_data > 0 && var.num_days_after_which_delete_log_data > 0 ? 1 : 0

  bucket        = var.s3_bucket_name
  acl           = "private"
  policy        = local.s3_bucket_policy
  force_destroy = var.force_destroy
  tags          = var.tags

  # There will never be a legitimate reason to overwrite a log entry, but if it does happen, enable S3 Bucket versioning
  # to ensure that the the original log files remain untouched.
  versioning {
    enabled = true
  }

  # Automatically archive a log file after X days and delete after Y days.
  lifecycle_rule {
    # The id is the name of the lifecycle rule in the AWS Web Console
    id                                     = "auto-archive-after-${var.num_days_after_which_archive_log_data}-days-and-delete-after-${var.num_days_after_which_delete_log_data}-days"
    prefix                                 = local.log_bucket_key_prefix
    enabled                                = true
    abort_incomplete_multipart_upload_days = var.num_days_after_which_archive_log_data

    # Transfer data from S3 to Glacier
    transition {
      days          = var.num_days_after_which_archive_log_data
      storage_class = "GLACIER"
    }

    # First an object becomes "expired". Given that we've enabled S3 versioning, this means the "current" object is
    # marked with a "delete marker" but still available as a "non-current" (previous) version. Note that if
    # var.num_days_after_which_delete_log_data == 0, then this will be a no-op.
    expiration {
      days = var.num_days_after_which_delete_log_data
    }

    # Permanently delete the object by expiring the "non-current" object.
    noncurrent_version_expiration {
      days = var.num_days_after_which_delete_log_data
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# DEFINE THE S3 BUCKET POLICY
# The sole permission needed for this Bucket is the ability for the AWS ELB Service Account to write logs.
# ----------------------------------------------------------------------------------------------------------------------

locals {
  s3_bucket_policy = var.s3_bucket_policy != null ? var.s3_bucket_policy : data.aws_iam_policy_document.access_logs_bucket_policy.json
}

# Per https://goo.gl/sIBJ4H, we need the AWS Account ID of the ELB Service Account to grant that account permission to
# write to our S3 Bucket used for the ELB/ALB's logs.
data "aws_elb_service_account" "main" {}

# Create the IAM Policy that grants the ELB Service Account permission to write to our S3 Bucket.
data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    sid    = "enable_load_balancer_to_write_logs"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/${local.log_bucket_key_prefix}/*",
    ]

    # ELBs and ALBs
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.main.id}:root"]
    }

    # NLBs
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# LOCALS
# These are global constants used throughout the module 
# ----------------------------------------------------------------------------------------------------------------------

locals {
  log_bucket_key_prefix = "${var.s3_logging_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
