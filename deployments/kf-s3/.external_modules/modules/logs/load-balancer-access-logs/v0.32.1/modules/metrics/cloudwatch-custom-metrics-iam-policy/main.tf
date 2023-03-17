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

    # Note: This policy will grant "ec2:DescribeTags" permission for all resources ("*"). According to AWS 
    # documentation, this is required in to read information from the instance and write it to CloudWatch.
    # Additional reading:
    #   https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/iam-identity-based-access-control-cw.html
    #   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-scripts-intro.html#mon-scripts-permissions
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }
}
