terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.68, < 4.0"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_alarm" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.function_name}-alarm"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  datapoints_to_alarm = var.datapoints_to_alarm
  metric_name         = var.metric_name
  namespace           = "AWS/Lambda"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Indicates that the lambda function ${var.function_name} failed"

  dimensions = {
    FunctionName = var.function_name
  }

  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
}
