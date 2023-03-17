# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM POLICY THAT ADDS CLOUDWATCH LOG AGGREGATION PERMISSIONS
# To use this IAM policy, use an aws_iam_policy_attachment resource.
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "cloudwatch_log_aggregation" {
  count       = var.create_resources ? 1 : 0
  name        = "${var.name_prefix}-cloudwatch-log-aggregation"
  description = "A policy that grants the ability to write data to CloudWatch Logs, which you need to use CloudWatch for log aggregation"

  policy = data.aws_iam_policy_document.cloudwatch_logs_permissions.json
}

data "aws_iam_policy_document" "cloudwatch_logs_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}
