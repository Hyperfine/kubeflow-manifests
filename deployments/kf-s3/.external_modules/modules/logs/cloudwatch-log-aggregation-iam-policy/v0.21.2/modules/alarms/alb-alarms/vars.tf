# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ELB alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "alb_arn" {
  description = "The Amazon Resource Name (ARN) of the ALB"
  type        = string
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# Each CloudWatch Alarm defines the following properties:
# ---------------------------------------------------------------------------------------------------------------------

# ActiveConnectionCount - High Count

variable "alb_high_active_connection_count_threshold" {
  description = "If the number of active connections the ALB has over a period of alb_active_connection_count_period goes above this number, trigger an alarm. Enter 0 to disable to this alarm."
  type        = number
  default     = 60000
}

variable "alb_high_active_connection_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_active_connection_count_period" {
  description = "The period, in seconds, over which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_active_connection_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_active_connection_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# ActiveConnectionCount - Low Count

variable "alb_low_active_connection_count_threshold" {
  description = "If the number of active connections the ALB has over a period of alb_active_connection_count_period goes above this number, trigger an alarm. Enter 0 to disable to this alarm."
  type        = number
  default     = 0
}

variable "alb_low_active_connection_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_low_active_connection_count_period" {
  description = "The period, in seconds, over which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_low_active_connection_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_low_active_connection_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# ClientTLSNegotiationErrorCount - High Count

variable "alb_high_client_tls_negotiation_error_count_threshold" {
  description = "If the number of TLS connections initiated by the client that did not establish a session with the ALB over a duration of alb_client_tls_negotiation_error_count_evaluation_periods goes above this number, trigger an alarm. Possible causes include a mismatch of ciphers or protocols. Enter 0 to disable this alarm."
  type        = number
  default     = 10
}

variable "alb_high_client_tls_negotiation_error_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_client_tls_negotiation_error_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_client_tls_negotiation_error_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_client_tls_negotiation_error_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# HTTPCode_ELB_4XX_Count - High Count

variable "alb_high_http_code_4xx_count_threshold" {
  description = "If the number of HTTP 4XX client error codes originating from the ALB goes above this number, trigger an alarm. These requests have not been received by the target. This count does not include any response codes generated by the targets. Enter 0 to disable this alarm."
  type        = number
  default     = 15
}

variable "alb_high_http_code_4xx_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_http_code_4xx_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_http_code_4xx_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_http_code_4xx_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# HTTPCode_ELB_5XX_Count - High Count

variable "alb_high_http_code_5xx_count_threshold" {
  description = "If the number of HTTP 5XX client error codes originating from the ALB goes above this number, trigger an alarm. These requests have not been received by the target. This count does not include any response codes generated by the targets. Enter 0 to disable this alarm."
  type        = number
  default     = 5
}

variable "alb_high_http_code_5xx_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_http_code_5xx_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_http_code_5xx_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_http_code_5xx_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# NewConnectionCount - High Count

variable "alb_high_new_connection_count_threshold" {
  description = "If the number of new TCP connections established from clients to the ALB and from the ALB to targets goes above this number, trigger an alarm. Enter 0 to disable this alarm."
  type        = number
  default     = 5000
}

variable "alb_high_new_connection_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_new_connection_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_new_connection_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_new_connection_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# NewConnectionCount - Low Count

variable "alb_low_new_connection_count_threshold" {
  description = "If the number of new TCP connections established from clients to the ALB and from the ALB to targets goes below this number, trigger an alarm. Enter 0 to disable this alarm."
  type        = number
  default     = 0
}

variable "alb_low_new_connection_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_low_new_connection_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_low_new_connection_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_low_new_connection_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# RejectedConnectionCount - High Count

variable "alb_high_rejected_connection_count_threshold" {
  description = "If the number of connections rejected because the ALB reached its maximum number of connections goes above this number, trigger an alarm. Enter 0 to disable the alarm."
  type        = number
  default     = 5
}

variable "alb_high_rejected_connection_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_rejected_connection_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_rejected_connection_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_rejected_connection_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# RequestCount - High Count

variable "alb_high_request_count_threshold" {
  description = "If the number of requests received by the ALB goes above this number, trigger an alarm. Enter 0 to disable the alarm."
  type        = number
  default     = 0
}

variable "alb_high_request_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_high_request_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_high_request_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_high_request_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

# RequestCount - Low Count

variable "alb_low_request_count_threshold" {
  description = "If the number of requests received by the ALB goes below this number, trigger an alarm. Enter 0 to disable the alarm."
  type        = number
  default     = 0
}

variable "alb_low_request_count_evaluation_periods" {
  description = "The number of periods after which the CloudWatch Metric statistic is compared to the specified threshold before an alarm is triggered."
  type        = number
  default     = 1
}

variable "alb_low_request_count_period" {
  description = "The period, in seconds, after which the CloudWatch Metric statistic is compared to the specified threshold."
  type        = number
  default     = 60
}

variable "alb_low_request_count_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "alb_low_request_count_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
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
