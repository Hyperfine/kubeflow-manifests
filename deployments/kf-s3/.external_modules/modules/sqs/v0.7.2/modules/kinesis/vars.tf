# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the Kinesis stream."
  type        = string
}

# https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html
variable "shard_level_metrics" {
  description = "The additional shard-level CloudWatch metrics to enable"
  type        = list(string)
  default     = []

  # Possible Values:
  #
  # shard_level_metrics = [
  #   "IncomingBytes",
  #   "IncomingRecords",
  #   "IteratorAgeMilliseconds",
  #   "OutgoingBytes",
  #   "OutgoingRecords",
  #   "ReadProvisionedThroughputExceeded",
  #   "WriteProvisionedThroughputExceeded"
  # ]
}

variable "retention_period" {
  description = "Length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours. Minimum value is 24."
  type        = number
  default     = 24
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# MODULE SIZING PARAMETERS
# These variables will be used for calculating the number of shards needed for the stream
# NOTE: You should EITHER set number_of_shards (to set the number of shards directly) OR set the other variables in this
# section for the number of shards to be caculated based on AWS guidance located at:
# https://docs.aws.amazon.com/streams/latest/dev/amazon-kinesis-streams.html

variable "number_of_shards" {
  description = "A shard is a group of data records in a stream. When you create a stream, you specify the number of shards for the stream."
  type        = number
  default     = null
}

variable "average_data_size_in_kb" {
  description = "The average size of the data record written to the stream in kilobytes (KB), rounded up to the nearest 1 KB"
  type        = number
  default     = 0
}

variable "records_per_second" {
  description = "The number of data records written to and read from the stream per second"
  type        = number
  default     = 0
}

variable "number_of_consumers" {
  description = "The number of Amazon Kinesis Streams applications that consume data concurrently and independently from the stream, that is, the consumers"
  type        = number
  default     = 0
}

# ENCRYPTION PARAMETERS
# These variables can be used to enable encryption on the stream

variable "encryption_type" {
  description = "The type of encryption to use (can be KMS or NONE)"
  type        = string
  default     = "NONE"
}

variable "kms_key_id" {
  description = "ID of the key to use for KMS"
  type        = string
  default     = "alias/aws/kinesis"
}

# OTHER PARAMETERS

variable "enforce_consumer_deletion" {
  description = "A boolean that indicates all registered consumers should be deregistered from the stream so that the stream can be destroyed without error."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to the Kinesis stream."
  type        = map(string)
  default     = {}
}
