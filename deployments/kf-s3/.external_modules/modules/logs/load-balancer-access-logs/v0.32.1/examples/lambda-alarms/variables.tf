variable "name" {
  description = "The name for the Lambda function. Used to namespace all resources created by this module."
  type        = string
  default     = "lambda-build-example"
}

variable "aws_region" {
  description = "The AWS region to deploy to (e.g. us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "sns_topic_name" {
  description = "The name of the SNS Topic to be used for alerting failures of this lambda function"
  type        = string
  default     = "lambda-example-sns-topic"
}
