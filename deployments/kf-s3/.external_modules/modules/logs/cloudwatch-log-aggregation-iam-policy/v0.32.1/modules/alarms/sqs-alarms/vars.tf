# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the RDS alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "sqs_queue_names" {
  description = "The list of names of the SQS queues"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# Each CloudWatch Alarm defines the following properties:
# ---------------------------------------------------------------------------------------------------------------------

# SQS - High number of visible messages

variable "high_approximate_number_of_messages_visible_threshold" {
  description = "Trigger an alarm if the number of visible messages in SQS queue (number of messages to be processed) is above this threshold"
  type        = number
  default     = 10
}

variable "high_approximate_number_of_messages_visible_period" {
  description = "The period, in seconds, over which to measure. The minimum value is 60 seconds as CloudWatch metrics for your Amazon SQS queues are automatically collected and pushed to CloudWatch at one-minute intervals. see https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html"
  type        = number
  default     = 60
}

variable "high_approximate_number_of_messages_visible_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "high_approximate_number_of_messages_visible_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Maximum"
}

variable "high_approximate_number_of_messages_visible_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_approximate_number_of_messages_visible_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "notBreaching"
}

# SQS - Old messages in queue

variable "high_approximate_age_of_oldest_message_threshold" {
  description = "Trigger an alarm if oldest messages in SQS queue surpass threshold"
  type        = number
  default     = 600
}

variable "high_approximate_age_of_oldest_message_period" {
  description = "The period, in seconds, over which to measure. The minimum value is 60 seconds as CloudWatch metrics for your Amazon SQS queues are automatically collected and pushed to CloudWatch at one-minute intervals. see https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html"
  type        = number
  default     = 60
}

variable "high_approximate_age_of_oldest_message_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "high_approximate_age_of_oldest_message_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Maximum"
}

variable "high_approximate_age_of_oldest_message_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_approximate_age_of_oldest_message_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "notBreaching"
}

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}