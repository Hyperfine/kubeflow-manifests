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

resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = var.dashboards

  dashboard_name = each.key
  dashboard_body = jsonencode(
    {
      "widgets" = each.value
    },
  )
}
