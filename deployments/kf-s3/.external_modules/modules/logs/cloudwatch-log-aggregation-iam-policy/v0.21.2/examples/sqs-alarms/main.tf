# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN SQS QUEUE AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to create an Simple Queue Service (SQS) queue and how to attach alarms to it that go off
# if the number of visible messages is too high or age of oldest message surpasses the threshold.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SQS QUEUE
# ---------------------------------------------------------------------------------------------------------------------

module "sqs" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/sqs?ref=v0.3.0"

  name              = var.queue_name
  dead_letter_queue = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALARMS FOR THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

module "sqs_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/sqs-alarms?ref=v0.12.1"
  source = "../../modules/alarms/sqs-alarms"

  sqs_queue_names                                       = [module.sqs.queue_name]
  high_approximate_number_of_messages_visible_threshold = 5
  alarm_sns_topic_arns                                  = [aws_sns_topic.cloudwatch_alarms.arn]
}

module "sqs_dl_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/sqs-alarms?ref=v0.12.1"
  source = "../../modules/alarms/sqs-alarms"

  sqs_queue_names                                       = [module.sqs.dead_letter_queue_name]
  high_approximate_number_of_messages_visible_threshold = 1
  alarm_sns_topic_arns                                  = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.queue_name}-sqs-alarms"
}
