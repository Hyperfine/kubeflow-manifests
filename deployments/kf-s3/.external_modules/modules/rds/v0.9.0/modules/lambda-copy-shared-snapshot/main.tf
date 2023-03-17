# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A LAMBDA FUNCTION TO CREATE LOCAL COPIES OF SHARED RDS SNAPSHOTS
# This is a way to create a backup copy of an RDS snapshot shared from another AWS account
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

module "copy_shared_snapshot" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/lambda?ref=v0.6.0"

  name        = var.lambda_namespace == null ? "${var.rds_db_identifier}-copy-snapshot" : var.lambda_namespace
  description = "Make a local copy of RDS snapshots shared from AWS account ${var.external_account_id}"

  source_path = "${path.module}/copy-shared-rds-snapshot"
  handler     = "index.handler"
  runtime     = "python2.7"

  timeout     = 300
  memory_size = 128

  environment_variables = {
    DB_IDENTIFIER        = var.rds_db_identifier
    DB_IS_AURORA_CLUSTER = var.rds_db_is_aurora_cluster ? "true" : "false"
    DB_ACCOUNT_ID        = var.external_account_id
    METRIC_NAMESPACE     = var.report_cloudwatch_metric_namespace
    METRIC_NAME          = var.report_cloudwatch_metric_name
    KMS_KEY_ID           = var.kms_key_id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RUN THE LAMBDA FUNCTION ON A SCHEDULED BASIS
# ---------------------------------------------------------------------------------------------------------------------

module "create_snapshot_schedule" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/scheduled-lambda-job?ref=v0.6.0"

  lambda_function_name = module.copy_shared_snapshot.function_name
  lambda_function_arn  = module.copy_shared_snapshot.function_arn
  schedule_expression  = var.schedule_expression
  namespace            = var.schedule_namespace
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM PERMISSIONS THAT ALLOW THE LAMBDA FUNCTION TO TALK TO RDS AND CLOUDWATCH
# ---------------------------------------------------------------------------------------------------------------------

# Get the current AWS region
data "aws_region" "current" {}

# Get the current AWS account
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "copy_shared_snapshot_permissions" {
  name   = "copy-shared-snapshot-permissions"
  role   = module.copy_shared_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.copy_shared_snapshot_permissions.json
}

data "aws_iam_policy_document" "copy_shared_snapshot_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBClusterSnapshots",
      "rds:DescribeDBSnapshots",
      "rds:CopyDBClusterSnapshot",
      "rds:CopyDBSnapshot",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "report_cloudwatch_metric_permissions" {
  count = var.report_cloudwatch_metric ? 1 : 0

  name   = "report-cloudwatch-metric"
  role   = module.copy_shared_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.report_cloudwatch_metric_permissions.*.json[count.index]
}

data "aws_iam_policy_document" "report_cloudwatch_metric_permissions" {
  count = var.report_cloudwatch_metric ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = ["*"]
  }
}
