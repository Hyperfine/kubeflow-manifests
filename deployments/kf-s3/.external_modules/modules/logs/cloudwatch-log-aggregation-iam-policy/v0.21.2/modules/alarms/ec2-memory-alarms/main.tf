# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A CLOUDWATCH ALARM FOR HIGH MEMORY USAGE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ec2_high_memory_utilization" {
  count             = var.create_resources ? var.instance_count : 0
  alarm_name        = "ec2-high-memory-utilization-${var.instance_ids[count.index]}"
  alarm_description = "An alarm that goes off if the EC2 Instance ${var.instance_ids[count.index]} is close to running out of memory."
  namespace         = "System/Linux"
  metric_name       = "MemoryUtilization"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_memory_utilization_evaluation_periods
  period                    = var.high_memory_utilization_period
  statistic                 = var.high_memory_utilization_statistic
  threshold                 = var.high_memory_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
