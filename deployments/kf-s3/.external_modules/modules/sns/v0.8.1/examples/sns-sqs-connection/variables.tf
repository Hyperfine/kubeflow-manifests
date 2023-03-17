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

# Note: the Region should match the SNS region
variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "sns_topic_arn" {
  description = "The arn of the topic to subscribe to."
  type        = string
  # Note:  This will usually be specified via a dependancy,
  #        formatted like "arn:aws:sns:us-east-1:123456789012:test-sns"
  #
  # Example:
  #
  # dependency "sns-topic" {
  #   config_path = "${get_terragrunt_dir()}/../../sns-topics/srcTopic"
  # }
  #
  # inputs = {
  #   sns_topic_arn = dependency.sns-topic.outputs.topic_arn
  # }
}
variable "sqs_arn" {
  description = "The queue arn for the Simple Queue Service (SQS)."
  type        = string
  # Note:  This will usually be specified via a dependancy,
  #        formatted like "arn:aws:sqs:us-west-1:123456789012:test-queue"
  #
  # Example:
  #
  # dependency "sqs-queue" {
  #   config_path = "${get_terragrunt_dir()}/../../sqs/destQueue"
  # }
  #
  # inputs = {
  #   sqs_arn = dependency.sqs-queue.outputs.queue_arn
  # } 
}

variable "sqs_queue_url" {
  description = "The queue URL for the Simple Queue Service (SQS)."
  type        = string
  # Note:  This will usually be specified via a dependancy,
  #        formatted like "https://sqs.us-east-1.amazonaws.com/123456789012/test-queue"
  #
  # Example:
  #  
  # dependency "sqs-queue" {
  #   config_path = "${get_terragrunt_dir()}/../../sqs/destQueue"
  # }
  #
  # inputs = {
  #   sqs_queue_url = dependency.sqs-queue.outputs.queue_url
  # }
}