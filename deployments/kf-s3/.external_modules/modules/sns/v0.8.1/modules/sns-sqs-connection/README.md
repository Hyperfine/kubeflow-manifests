# Simple Notification Service (SNS) Topic to Simple Queuing Service (SQS) Connection Module 

This module makes it easy to subscribe a SQS to a SNS topic after both have been successfully created.

## How do you use this module?

* See the [root README](./README.md) for instructions on using Terraform modules.
* See the [examples](./examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.

Here is an example of how you might deploy an SNS topic with this module:

```hcl
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sns-sqs-connection?ref=v0.0.1"
}

dependency "sns-topic" {
  config_path = "${get_terragrunt_dir()}/../../sns-topics/srcTopic"
}

dependency "sqs-queue" {
  config_path = "${get_terragrunt_dir()}/../../sqs/destQueue"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  sns_topic_arn = dependency.sns-topic.outputs.topic_arn
  sqs_arn = dependency.sqs-queue.outputs.queue_arn
  sqs_queue_url = dependency.sqs-queue.outputs.queue_url
}
```

