# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "slack_webhook_url" {
  description = "The Slack Webhook URL which that alarms are sent to, ex: https://hooks.slack.com/services/FOO/BAR/BAZ"
  type        = string
}

variable "sns_topic_arn" {
  description = "The ARN for the SNS topic that will get forwarded to Slack."
  type        = string
}

variable "lambda_function_name" {
  description = "The name for the lambda function and other resources created by these Terraform configurations"
  type        = string
}

variable "create_resources" {
  description = "Set to false to have this module create no resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the Lambda function and other resources should be created or not."
  type        = bool
  default     = true
}
