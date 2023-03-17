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

variable "lambda_arn" {
  description = "The Lambda arn to trigger"
  type        = string
  # Note:  This will usually be specified via a dependancy,
  #        formatted like "arn:aws:lambda:us-west-1:123456789012:function:my-lambda-name"
  #
  # Example:
  #  
  # dependency "lambda" {
  #   config_path = "${get_terragrunt_dir()}/../../lambda/destLambda"
  # }
  #
  # inputs = {
  #   lambda_arn = dependency.lambda.outputs.function_arn
  # }
}

variable "batch_size" {
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation. Defaults to 10 for SQS"
  type        = number
  default     = 10
  # Note:  Terraform defaults to 10
}