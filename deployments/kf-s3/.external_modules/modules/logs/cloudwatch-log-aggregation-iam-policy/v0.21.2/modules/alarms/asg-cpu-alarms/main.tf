# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A CLOUDWATCH ALARM FOR HIGH CPU USAGE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu_utilization" {
  count             = var.create_resources ? var.num_asg_names : 0
  alarm_name        = "${var.asg_names[count.index]}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high on EC2 Instances in the ${var.asg_names[count.index]} ASG."
  namespace         = "AWS/EC2"
  metric_name       = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = var.asg_names[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_cpu_utilization_evaluation_periods
  period                    = var.high_cpu_utilization_period
  statistic                 = var.high_cpu_utilization_statistic
  threshold                 = var.high_cpu_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
