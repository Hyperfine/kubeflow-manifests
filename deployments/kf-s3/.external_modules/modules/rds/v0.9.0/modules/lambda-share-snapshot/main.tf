# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A LAMBDA FUNCTION TO SHARES SNAPSHOTS OF AN RDS DATABASE WITH ANOTHER AWS ACCOUNT
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

module "share_snapshot" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/lambda?ref=v0.6.0"

  name        = var.name
  description = "Share an RDS snapshot with another AWS account"

  source_path = "${path.module}/share-rds-snapshot"
  handler     = "index.handler"
  runtime     = "python2.7"

  timeout     = 300
  memory_size = 128

  environment_variables = {
    MAX_RETRIES               = var.max_retries
    SLEEP_BETWEEN_RETRIES_SEC = var.sleep_between_retries_sec
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE THE LAMBDA FUNCTION PERMISSIONS TO LOG TO CLOUDWATCH
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "logging_for_lambda" {
  name   = "logging-for-lambda"
  role   = module.share_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.logging_for_lambda.json
}

data "aws_iam_policy_document" "logging_for_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM PERMISSIONS THAT ALLOW THE LAMBDA FUNCTION TO TALK TO RDS, CLOUDWATCH, AND OTHER LAMBDA FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------

# Get the current AWS region
data "aws_region" "current" {}

# Get the current AWS account
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "share_snapshot_permissions" {
  name   = "share-snapshot-permissions"
  role   = module.share_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.share_snapshot_permissions.json
}

data "aws_iam_policy_document" "share_snapshot_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBClusterSnapshots",
      "rds:DescribeDBSnapshots",
      "rds:ModifyDBClusterSnapshotAttribute",
      "rds:ModifyDBSnapshotAttribute",
    ]

    resources = [
      var.rds_db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*",
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
    ]
  }
}

resource "aws_iam_role_policy" "invoke_self_permissions" {
  name   = "invoke-self-permissions"
  role   = module.share_snapshot.iam_role_id
  policy = data.aws_iam_policy_document.invoke_self_permissions.json
}

data "aws_iam_policy_document" "invoke_self_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [module.share_snapshot.function_arn]
  }
}
