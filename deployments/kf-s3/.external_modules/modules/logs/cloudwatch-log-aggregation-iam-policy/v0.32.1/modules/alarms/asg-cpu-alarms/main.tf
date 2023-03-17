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
# CREATE A CLOUDWATCH ALARM FOR HIGH CPU USAGE
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu_utilization" {
  count             = var.create_resources ? var.num_asg_names : 0
  alarm_name        = "${var.asg_names[count.index]}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high on EC2 Instances in the ${var.asg_names[count.index]} ASG."
  namespace         = var.cpu_metric_namespace
  metric_name       = var.cpu_metric_name

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
