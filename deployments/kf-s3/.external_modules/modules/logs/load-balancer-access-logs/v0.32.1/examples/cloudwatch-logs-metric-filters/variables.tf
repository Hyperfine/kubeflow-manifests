# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables.
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOGS METRIC FILTER PARAMETERS
# These variables are required to create the Cloudwatch Logs Metric Filter.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "cloudwatch_logs_group_name" {
  description = "The name of the CloudWatch Logs group to apply the pattern to."
  type        = string
}

# metric_map is a map of objects describing multiple metric filters and alarms.
# Each object key specifies a new metric filter. The object key is used for the name of the metric filter, the alarm, and
# the metric itself. The value of pattern is used by the metric filter. The value of description is used by the alarm.
#
# The following example creates two filter metrics that match JSON events sent by CloudTrail:
#
#   metric_map = {
#    "UnauthorizedAPICall" = {
#      pattern     = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
#      description = "Ensure a log metric filter and alarm exist for unauthorized API calls"
#    }
#    "CloudtrailMissingMFA" = {
#      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
#      description = "Ensure a log metric filter and alarm exist for unauthorized API calls"
#    }
#  }
variable "metric_map" {
  description = "A map of filter metrics."
  type = map(object({
    pattern     = string
    description = string
  }))
}

variable "metric_namespace" {
  description = "The namespace of the Cloudwatch Metric."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH METRIC ALARM PARAMETERS
# Creating an alarm is optional. Use these variables to configure the alarm.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_comparison_operator" {
  description = "How the metric value should be compared to the threshhold. Valid values: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold. "
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
}

variable "alarm_evaluation_periods" {
  description = "The number of periods to evaluate before changing state."
  type        = number
  default     = 1
}

variable "alarm_period" {
  description = "The number of seconds for which the given statistic is applied."
  type        = number
  default     = 300
}

variable "alarm_statistic" {
  description = "The statistic to apply to the metric when determining alarm state. Valid values: SampleCount, Average, Sum, Minimum, Maximum."
  type        = string
  default     = "Sum"
}

variable "alarm_threshold" {
  description = "A value that determines what constitutes a Alarm state for computed metric statistic."
  type        = number
  default     = 1
}

variable "alarm_treat_missing_data" {
  description = "How to treat empty (missing) metric data. Valid values: missing, ignore, breaching and notBreaching. Defaults to notbreaching."
  type        = string
  default     = "notBreaching"
}

# ---------------------------------------------------------------------------------------------------------------------
# SNS TOPIC PARAMETERS
# Provide a name and allow the module create an SNS topic
# ---------------------------------------------------------------------------------------------------------------------

variable "sns_topic_name" {
  description = "The name of an SNS topic to notify of alarm status changes."
  type        = string
  default     = null
}
