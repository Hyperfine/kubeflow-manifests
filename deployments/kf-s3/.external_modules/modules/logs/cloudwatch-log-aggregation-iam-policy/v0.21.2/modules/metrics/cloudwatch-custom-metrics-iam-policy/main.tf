# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE AN IAM POLICY THAT ADDS PERMISSIONS FOR READING AND WRITING CLOUDWATCH METRICS
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "cloudwatch_metrics_read_write" {
  count = var.create_resources ? 1 : 0

  name        = "${var.name_prefix}-cloudwatch-metrics-read-write"
  description = "A policy that grants the ability to read and write data CloudWatch metrics"

  policy = data.aws_iam_policy_document.cloudwatch_metrics_read_write_permissions.json
}

data "aws_iam_policy_document" "cloudwatch_metrics_read_write_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }
}
