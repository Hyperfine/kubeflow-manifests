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

resource "aws_cloudwatch_metric_alarm" "ec2_high_disk_utilization" {
  count             = var.create_resources ? var.instance_count : 0
  alarm_name        = "ec2-high-disk-utilization-${var.instance_ids[count.index]}-${var.file_system}-${var.mount_path}"
  alarm_description = "An alarm that goes off if the EC2 Instance ${var.instance_ids[count.index]} is close to running out of disk space."
  namespace         = "System/Linux"
  metric_name       = "DiskSpaceUtilization"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
    Filesystem = var.file_system
    MountPath  = var.mount_path
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
  tags                      = var.tags
}
