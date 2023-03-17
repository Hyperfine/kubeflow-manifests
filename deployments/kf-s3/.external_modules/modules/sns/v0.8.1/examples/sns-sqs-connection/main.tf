terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

# Note: the Region should match the SNS region
provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CONNECT SNS TO SQS
# ---------------------------------------------------------------------------------------------------------------------

module "sns_sqs_connection" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sns?ref=v1.0.0"
  source = "../../modules/sns-sqs-connection"

  sns_topic_arn = var.sns_topic_arn
  sqs_arn       = var.sqs_arn
  sqs_queue_url = var.sqs_queue_url
}