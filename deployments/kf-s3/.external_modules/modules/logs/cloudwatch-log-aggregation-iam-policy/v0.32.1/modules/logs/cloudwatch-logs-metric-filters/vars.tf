# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOGS METRIC FILTER PARAMETERS
# These variables are required to create the Cloudwatch Logs Metric Filter. They must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "cloudwatch_logs_group_name" {
  description = "The name of the CloudWatch Logs group used by Cloudtrail."
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
# These variables are used to create the Cloudwatch Alarm.
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
# If an SNS topic already exists, supply an topic ARN for the alarm to notify.
# If an SNS topic does not exist, supply a topic name and the module will create it.
# ---------------------------------------------------------------------------------------------------------------------

variable "sns_topic_already_exists" {
  description = "If set to true, that means the SNS topic already exists and does not need to be created. You must set var.sns_topic_arn when this is set to true."
  # Ideally, this variable isn't necessary but this works around an issue with terraform count where it cannot evaluate
  # counts when they depend on resources that haven't been applied yet. This situation arises when `sns_topic_arn` is
  # an interpolation for an SNS topic resource created in the calling module.
  type    = bool
  default = false
}

variable "sns_topic_arn" {
  description = "The ARN of an existing SNS topic to notify of alarm status changes."
  type        = string
  default     = null
}

variable "sns_topic_name" {
  description = "The name of an SNS topic to notify of alarm status changes. Required if sns_topic_already_exists is false."
  type        = string
  default     = null
}

variable "sns_topic_kms_master_key_id" {
  description = "The ID of an AWS-managed or customer-managed customer master key (CMK) to use for encrypting the Amazon SNS topic. Only used if sns_topic_already_exists is false."
  type        = string
  default     = null
}