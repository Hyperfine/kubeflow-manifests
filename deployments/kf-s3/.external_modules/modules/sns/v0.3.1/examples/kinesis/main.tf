# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a Kinesis Stream
# see for additional information: https://aws.amazon.com/kinesis/
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A QUEUE
# ---------------------------------------------------------------------------------------------------------------------
module "kinesis" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/kinesis?ref=v1.0.0"
  source = "../../modules/kinesis"

  name                    = var.name
  number_of_shards        = var.number_of_shards
  shard_level_metrics     = var.shard_level_metrics
  average_data_size_in_kb = var.average_data_size_in_kb
  records_per_second      = var.records_per_second
  number_of_consumers     = var.number_of_consumers
  retention_period        = var.retention_period
  encryption_type         = var.encryption_type
  kms_key_id              = var.kms_key_id
}
