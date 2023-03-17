# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account."
  type        = string
}

variable "slack_webhook_url" {
  description = "The Slack Webhook URL which that alarms are sent to, ex: https://hooks.slack.com/services/FOO/BAR/BAZ"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name to use for the EC2 Instance and all other resources created by these templates"
  type        = string
  default     = "cloudwatch-to-slack-example"
}

variable "keypair_name" {
  description = "An SSH Key Pair that can be used to connect to the test EC2 Instance."
  type        = string
  default     = null
}

variable "ssh_port" {
  description = "The port the test EC2 Instance should listen on for SSH requests."
  type        = number
  default     = 22
}

variable "create_resources" {
  description = "Set to false to have this module create no resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the Lambda function and other resources should be created or not."
  type        = bool
  default     = true
}
