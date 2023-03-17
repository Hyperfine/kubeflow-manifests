variable "sns_topic_arn" {
  description = "The arn of the topic to subscribe to."
  type        = string
}
variable "sqs_arn" {
  description = "The queue arn for the Simple Queue Service (SQS)."
  type        = string
}


variable "sqs_queue_url" {
  description = "The queue URL for the Simple Queue Service (SQS)."
  type        = string
}