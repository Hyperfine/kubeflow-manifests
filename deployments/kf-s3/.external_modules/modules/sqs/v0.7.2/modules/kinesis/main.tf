# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON KINESIS STREAM
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE STREAM
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# NOTE: Shard Sizing
# ---------------------------------------------------------------------------------------------------------------------
# set number_of_shards to set the number of shards directly
# -OR-
# set the number_of_shards, average_data_size_in_kb and records_per_second and number_of_consumers vaiables to calculate
# the number of shards based on the best practices at:
#
# https://docs.aws.amazon.com/streams/latest/dev/amazon-kinesis-streams.html
#
# If both are set, number_of_shards overrides the calculated value
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kinesis_stream" "stream" {
  name = var.name

  shard_count = (
    var.number_of_shards == null
    ? max(
      floor(var.average_data_size_in_kb * var.records_per_second / 1000),
      floor(var.average_data_size_in_kb * var.records_per_second * var.number_of_consumers / 2000),
      # shard_count must be at least 1
      1,
    )
    : var.number_of_shards
  )

  enforce_consumer_deletion = var.enforce_consumer_deletion
  shard_level_metrics       = var.shard_level_metrics
  retention_period          = var.retention_period
  encryption_type           = var.encryption_type
  kms_key_id                = var.kms_key_id
  tags                      = var.tags
}
