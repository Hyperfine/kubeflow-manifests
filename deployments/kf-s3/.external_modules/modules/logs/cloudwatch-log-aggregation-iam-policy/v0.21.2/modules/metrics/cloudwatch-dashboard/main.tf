terraform {
  required_version = ">= 0.12"
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
