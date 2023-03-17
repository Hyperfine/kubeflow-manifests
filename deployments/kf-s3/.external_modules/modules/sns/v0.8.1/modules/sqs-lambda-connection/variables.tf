variable "sqs_arn" {
  description = "The arn of the queue."
  type        = string
}

variable "lambda_arn" {
  description = "The arn of the lambda."
  type        = string
}

variable "batch_size" {
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation. Defaults to 10 for SQS"
  type        = number
  default     = 10
}
