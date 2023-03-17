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
# CREATE A CLOUDWATCH ALARM FOR HIGH DISK SPACE USAGE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ec2_high_disk_utilization" {
  count             = var.create_resources ? var.instance_count : 0
  alarm_name        = "ec2-high-disk-utilization-${var.instance_ids[count.index]}-${var.device}-${var.mount_path}"
  alarm_description = "An alarm that goes off if the EC2 Instance ${var.instance_ids[count.index]} is close to running out of disk space."
  namespace         = var.disk_metric_namespace
  metric_name       = var.disk_metric_name

  dimensions = {
    InstanceId   = var.instance_ids[count.index]
    InstanceType = var.instance_type
    ImageId      = var.ami
    device       = var.device
    path         = var.mount_path
    fstype       = var.fstype
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
