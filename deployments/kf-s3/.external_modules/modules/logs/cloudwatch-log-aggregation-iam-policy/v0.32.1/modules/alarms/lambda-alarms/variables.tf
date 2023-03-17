# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the lambda function this alarm will monitor."
  type        = string
}

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the lambda alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified Statistic and Threshold. The specified Statistic value is used as the first operand. Either of the following is supported: `GreaterThanOrEqualToThreshold`, `GreaterThanThreshold`, `LessThanThreshold`, `LessThanOrEqualToThreshold`. Additionally, the values `LessThanLowerOrGreaterThanUpperThreshold`, `LessThanLowerThreshold`, and `GreaterThanUpperThreshold` are used only for alarms based on anomaly detection models."
  type        = string
  default     = "GreaterThanThreshold"
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm."
  type        = number
  default     = 1
}

variable "metric_name" {
  description = "The name for the alarm's associated metric. See the supported metrics docs https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics.html for available metrics. By default we use the 'Errors' metric which is the number of invocations that result in a function error. Function errors include exceptions thrown by your code and exceptions thrown by the Lambda runtime."
  type        = string
  default     = "Errors"
}

variable "period" {
  description = "The period in seconds over which the specified `statistic` is applied."
  type        = number
  default     = 60
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric."
  type        = string
  default     = "Sum"
}

variable "threshold" {
  description = "The value against which the specified statistic is compared. This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models."
  type        = number
  default     = 0.0
}

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}
