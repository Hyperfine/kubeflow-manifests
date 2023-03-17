# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "The name of the SNS topic that will be created"
  type        = string
}

variable "display_name" {
  description = "The display name of the SNS topic. NOTE: Maximum length is 10 characters."
  type        = string
  default     = ""
}

variable "allow_publish_accounts" {
  description = "A list of IAM ARNs that will be given the rights to publish to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:role/jenkins"
  # ]
}

variable "allow_publish_services" {
  description = "A list of AWS services that will be given the rights to publish to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "events.amazonaws.com"
  # ]
}

variable "allow_subscribe_accounts" {
  description = "A list of IAM ARNs that will be given the rights to subscribe to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:role/jenkins"
  # ]
}

variable "allow_subscribe_protocols" {
  description = ""
  type        = list(string)
  default = [
    "http",
    "https",
    "email",
    "email-json",
    "sms",
    "sqs",
    "application",
    "lambda",
  ]
}

variable "create_resources" {
  description = "Enable or disable creation of the resources of this module. Necessary workaround when it is desired to set count = 0 for modules, which is necessary to maintain backward compatibility with Terraform 0.12.26."
  type        = bool
  default     = true
}