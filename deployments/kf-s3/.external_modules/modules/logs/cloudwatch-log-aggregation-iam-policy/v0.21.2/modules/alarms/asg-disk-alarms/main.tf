# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A CLOUDWATCH ALARM FOR HIGH DISK SPACE USAGE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "asg_high_disk_utilization" {
  count             = var.create_resources ? var.num_asg_names : 0
  alarm_name        = "${var.asg_names[count.index]}-${var.file_system}-${var.mount_path}-high-disk-utilization"
  alarm_description = "An alarm that goes off if the EC2 Instances in the ${var.asg_names[count.index]} ASG are close to running out of disk space."
  namespace         = "System/Linux"
  metric_name       = "DiskSpaceUtilization"

  dimensions = {
    AutoScalingGroupName = var.asg_names[count.index]
    Filesystem           = var.file_system
    MountPath            = var.mount_path
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_disk_utilization_evaluation_periods
  period                    = var.high_disk_utilization_period
  statistic                 = var.high_disk_utilization_statistic
  threshold                 = var.high_disk_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.treat_missing_data
  tags                      = var.tags
}
