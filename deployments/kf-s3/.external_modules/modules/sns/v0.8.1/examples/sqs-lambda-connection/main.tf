terraform {
  required_version = ">= 0.15.0"
}
# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CONNECT SQS to LAMBDA TRIGGER
# ---------------------------------------------------------------------------------------------------------------------

module "sqs_lambda_connection" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sns?ref=v1.0.0"
  source = "../../modules/sqs-lambda-connection"

  sqs_arn    = var.sqs_arn
  lambda_arn = var.lambda_arn
  batch_size = var.batch_size
}
