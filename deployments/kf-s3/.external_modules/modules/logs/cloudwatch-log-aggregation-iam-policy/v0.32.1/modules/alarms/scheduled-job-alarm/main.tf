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
# CREATE A CLOUDWATCH ALARM FOR DETECTING IF A SCHEDULED JOB FAILED
# This alarm will go off if over a specified period, the metric does not reach
# a specified threshold. The most common use is checking that a metric has value
# 1 over a 24 hour period, as that is a sign that some scheduled job is
# successfully running once per day.
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "scheduled_job_failed" {
  count                     = var.create_resources ? 1 : 0
  alarm_name                = "${var.name}-scheduled-job-failed"
  alarm_description         = "An alarm that goes off if the scheduled job ${var.name} runs less than ${var.threshold} times per ${var.period} seconds."
  namespace                 = var.namespace
  metric_name               = var.metric_name
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.evaluation_periods
  period                    = var.period
  statistic                 = "Sum"
  threshold                 = var.threshold
  unit                      = var.unit
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
