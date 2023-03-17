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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE CLOUDWATCH ALARMS FOR SQS METRICS
# For detailed explanations of these metrics, see:
# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-available-cloudwatch-metrics.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_cloudwatch_metric_alarm" "sqs_approximate_number_of_messages_visible" {
  count             = var.create_resources ? length(var.sqs_queue_names) : 0
  alarm_name        = "${var.sqs_queue_names[count.index]}-approximate-number-of-messages-visible"
  alarm_description = "An alarm that goes off if the number of visible messages is too high in the SQS queue ${var.sqs_queue_names[count.index]}"
  namespace         = "AWS/SQS"
  metric_name       = "ApproximateNumberOfMessagesVisible"

  dimensions = {
    QueueName = var.sqs_queue_names[count.index]
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.high_approximate_number_of_messages_visible_evaluation_periods

  # The minimum value is 60 seconds as CloudWatch metrics for your Amazon SQS queues are automatically collected and pushed to CloudWatch at one-minute intervals.
  # see https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html
  period = max(60, var.high_approximate_number_of_messages_visible_period)

  datapoints_to_alarm       = var.high_approximate_number_of_messages_visible_datapoints_to_alarm == null ? var.high_approximate_number_of_messages_visible_evaluation_periods : var.high_approximate_number_of_messages_visible_datapoints_to_alarm
  statistic                 = var.high_approximate_number_of_messages_visible_statistic
  threshold                 = var.high_approximate_number_of_messages_visible_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_approximate_number_of_messages_visible_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "sqs_approximate_age_of_oldest_message" {
  count             = var.create_resources ? length(var.sqs_queue_names) : 0
  alarm_name        = "${var.sqs_queue_names[count.index]}-approximate-age-of-oldest-message-threshold"
  alarm_description = "An alarm that goes off when average time of oldest message surpasses the threshold in the SQS queue ${var.sqs_queue_names[count.index]}"
  namespace         = "AWS/SQS"
  metric_name       = "ApproximateAgeOfOldestMessage"

  dimensions = {
    QueueName = var.sqs_queue_names[count.index]
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.high_approximate_age_of_oldest_message_evaluation_periods

  # The minimum value is 60 seconds as CloudWatch metrics for your Amazon SQS queues are automatically collected and pushed to CloudWatch at one-minute intervals.
  # see https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html
  period = max(60, var.high_approximate_age_of_oldest_message_period)

  datapoints_to_alarm       = var.high_approximate_age_of_oldest_message_datapoints_to_alarm == null ? var.high_approximate_age_of_oldest_message_evaluation_periods : var.high_approximate_age_of_oldest_message_datapoints_to_alarm
  statistic                 = var.high_approximate_age_of_oldest_message_statistic
  threshold                 = var.high_approximate_age_of_oldest_message_threshold
  unit                      = "Seconds"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_approximate_age_of_oldest_message_treat_missing_data
  tags                      = var.tags
}
