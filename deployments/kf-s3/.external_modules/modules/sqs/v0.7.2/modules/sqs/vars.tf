# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the queue. Note that this module may append '.fifo' to this name depending on the value of var.fifo_queue."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# NOTE
# If var.apply_ip_queue_policy = true anonymous access will be allowed from any IP within var.allowed_cidr_blocks
# For more restrictive policies set var.apply_ip_queue_policy = false and add a custom policy outside of this module.
variable "allowed_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that are allowed to access this queue. Required when var.apply_ip_queue_policy = true."
  type        = list(string)

  # If var.apply_ip_queue_policy = true, a VALID CDIR block must be provided (e.g. "0.0.0.0/0")
  default = []
}

variable "apply_ip_queue_policy" {
  description = "Should the ip access policy be attached to the queue (using var.allowed_cidr_blocks)?"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days)."
  type        = number
  default     = 345600
  # 4 days
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB)."
  type        = number
  default     = 262144
  # 256 KiB
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes)."
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds). Setting this to 0 means the call will return immediately."
  type        = number
  default     = 0
}

variable "fifo_queue" {
  description = "Set to true to make this a FIFO queue."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Set to true to enable content-based deduplication for FIFO queues."
  type        = bool
  default     = false
}

variable "dead_letter_queue" {
  description = "Set to true to enable a dead letter queue. Messages that cannot be processed/consumed successfully will be sent to a second queue so you can set aside these messages and analyze what went wrong."
  type        = bool
  default     = false
}

variable "max_receive_count" {
  description = "The maximum number of times that a message can be received by consumers. When this value is exceeded for a message the message will be automatically sent to the Dead Letter Queue. Only used if var.dead_letter_queue is true."
  type        = number
  default     = 3
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (such as 'alias/aws/sqs') for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours)"
  type        = number
  default     = 300
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the sqs queue. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "custom_dlq_tags" {
  description = "A map of tags to apply to the dead letter queue, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "If you set this variable to false, this module will not create any resources. This is used as a workaround because Terraform does not allow you to use the 'count' parameter on modules. By using this parameter, you can optionally create or not create the resources within this module."
  type        = bool
  default     = true
}

variable "deduplication_scope" {
  description = "Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue (default). Only used if fifo_queue is set to true."
  type        = string
  default     = "queue"
}

variable "fifo_throughput_limit" {
  description = "Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue (default) and perMessageGroupId. Only used if fifo_queue is set to true."
  type        = string
  default     = "perQueue"
}
