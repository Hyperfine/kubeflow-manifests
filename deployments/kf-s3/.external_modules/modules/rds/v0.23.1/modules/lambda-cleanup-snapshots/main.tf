# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A LAMBDA FUNCTION TO DELETE OLD SNAPSHOTS OF AN RDS DATABASE ON A PERIODIC BASIS
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

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

module "delete_snapshots" {
  source           = "git::git@github.com:gruntwork-io/terraform-aws-lambda.git//modules/lambda?ref=v0.13.2"
  create_resources = var.create_resources

  name        = var.lambda_namespace == null ? "${var.rds_db_identifier}-delete-snapshots" : var.lambda_namespace
  description = "Delete old snapshots of the RDS DB ${var.rds_db_identifier} on a periodic basis"

  source_path = "${path.module}/cleanup-rds-snapshots"
  handler     = "index.handler"
  runtime     = "python3.7"

  timeout     = 300
  memory_size = 128

  environment_variables = {
    DB_IDENTIFIER        = var.rds_db_identifier
    DB_IS_AURORA_CLUSTER = var.rds_db_is_aurora_cluster ? "true" : "false"
    MAX_SNAPSHOTS        = var.max_snapshots
    ALLOW_DELETE_ALL     = var.allow_delete_all
    SNAPSHOT_NAMESPACE   = var.snapshot_namespace
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RUN THE LAMBDA FUNCTION ON A SCHEDULED BASIS
# ---------------------------------------------------------------------------------------------------------------------

module "create_snapshot_schedule" {
  source           = "git::git@github.com:gruntwork-io/terraform-aws-lambda.git//modules/scheduled-lambda-job?ref=v0.13.2"
  create_resources = var.create_resources

  lambda_function_name = module.delete_snapshots.function_name
  lambda_function_arn  = module.delete_snapshots.function_arn
  schedule_expression  = var.schedule_expression
  namespace            = var.schedule_namespace
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM PERMISSIONS THAT ALLOW THE LAMBDA FUNCTION TO TALK TO RDS
# ---------------------------------------------------------------------------------------------------------------------

# Get the current AWS region
data "aws_region" "current" {}

# Get the current AWS account
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "delete_snapshots_permissions" {
  count  = var.create_resources ? 1 : 0
  name   = "delete-snapshots-permissions"
  role   = module.delete_snapshots.iam_role_id
  policy = data.aws_iam_policy_document.delete_snapshots_permissions.json
}

data "aws_iam_policy_document" "delete_snapshots_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBSnapshots",
      "rds:DeleteDBClusterSnapshot",
      "rds:DeleteDBSnapshot",
    ]

    resources = [
      var.rds_db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*",
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
    ]
  }

  # DescribeDBClusterSnapshots action is not resource aware
  # https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBClusterSnapshots.html
  statement {
    actions = [
      "rds:DescribeDBClusterSnapshots",
    ]

    resources = [
      "*",
    ]
  }
}
