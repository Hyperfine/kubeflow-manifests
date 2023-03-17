# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A LAMBDA FUNCTION TO TAKE SNAPSHOTS OF AN RDS DATABASE ON A PERIODIC BASIS
# This lambda function can also, optionally, a) trigger another lambda function to share the snapshot with another AWS
# account and b) report a metric to CloudWatch to indicate the backup completed successfully.
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

module "create_snapshot" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/lambda?ref=v0.6.0"

  name        = var.lambda_namespace == null ? "${var.rds_db_identifier}-create-snapshot" : var.lambda_namespace
  description = "Take a periodic snapshot of the RDS DB ${var.rds_db_identifier}"

  source_path = "${path.module}/create-rds-snapshot"
  handler     = "index.handler"
  runtime     = "python2.7"

  timeout     = 300
  memory_size = 128

  environment_variables = {
    DB_IDENTIFIER                          = var.rds_db_identifier
    DB_IS_AURORA_CLUSTER                   = var.rds_db_is_aurora_cluster ? "true" : "false"
    SHARE_RDS_SNAPSHOT_LAMBDA_FUNCTION_ARN = var.share_snapshot_lambda_arn
    SHARE_RDS_SNAPSHOT_WITH_ACCOUNT_ID     = var.share_snapshot_with_account_id
    METRIC_NAMESPACE                       = var.report_cloudwatch_metric_namespace
    METRIC_NAME                            = var.report_cloudwatch_metric_name
    MAX_RETRIES                            = var.max_retries
    SLEEP_BETWEEN_RETRIES_SEC              = var.sleep_between_retries_sec
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RUN THE LAMBDA FUNCTION ON A SCHEDULED BASIS
# ---------------------------------------------------------------------------------------------------------------------

module "create_snapshot_schedule" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/scheduled-lambda-job?ref=v0.6.0"

  lambda_function_name = module.create_snapshot.function_name
  lambda_function_arn  = module.create_snapshot.function_arn
  schedule_expression  = var.schedule_expression
  namespace            = var.schedule_namespace
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM PERMISSIONS THAT ALLOW THE LAMBDA FUNCTION TO TALK TO RDS, CLOUDWATCH, AND OTHER LAMBDA FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------

# Get the current AWS region
data "aws_region" "current" {}

# Get the current AWS account
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "create_snapshot_permissions" {
  name   = "create-snapshot-permissions"
  role   = module.create_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.create_snapshot_permissions.json
}

data "aws_iam_policy_document" "create_snapshot_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "rds:CreateDBClusterSnapshot",
      "rds:CreateDBSnapshot",
    ]

    resources = [
      var.rds_db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*",
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
    ]
  }
}

resource "aws_iam_role_policy" "share_snapshot_with_another_account_permissions" {
  count = var.share_snapshot_with_another_account ? 1 : 0

  name   = "share-snapshot-with-another-account"
  role   = module.create_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.share_snapshot_with_another_account_permissions.*.json[count.index]
}

data "aws_iam_policy_document" "share_snapshot_with_another_account_permissions" {
  count = var.share_snapshot_with_another_account ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [var.share_snapshot_lambda_arn]
  }
}

resource "aws_iam_role_policy" "retry_self_permissions" {
  count = var.share_snapshot_with_another_account ? 1 : 0

  name   = "retry-self-permissions"
  role   = module.create_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.retry_self_permissions.*.json[count.index]
}

data "aws_iam_policy_document" "retry_self_permissions" {
  count = var.share_snapshot_with_another_account ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [module.create_snapshot.function_arn]
  }
}

resource "aws_iam_role_policy" "report_cloudwatch_metric_permissions" {
  count = var.report_cloudwatch_metric ? 1 : 0

  name   = "report-cloudwatch-metric"
  role   = module.create_snapshot.iam_role_id
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
