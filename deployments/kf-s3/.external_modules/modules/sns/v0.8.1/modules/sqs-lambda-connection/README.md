# Simple Queuing Service (SQS) To Lambda Connection Module 

This module wraps the basics for using SQS to trigger a Lambda for processing

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.

Here is an example of how you might use a SQS to trigger a Lambda to process the queue:

```hcl
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sqs-lambda-connection?ref=v0.0.1"
}

dependency "sqs-queue" {
  config_path = "${get_terragrunt_dir()}/../../sqs/srcQueue"
}

dependency "lambda" {
  config_path = "${get_terragrunt_dir()}/../../lambdas/destLambda"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  sqs_arn    = dependency.sqs-queue.outputs.queue_arn
  lambda_arn = dependency.lambda.outputs.function_arn
}
```

Note:
  When generating the policy document for the Lambda, you should include a block like:

```json
  {
    "Sid": "LambdaSqsAccess",
    "Effect": "Allow",
    "Action": [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ListDeadLetterSourceQueues",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ListQueueTags"
    ],
    "Resource": "*"
  },
  {
    "Sid": "LambdaSqsListAllQueues",
    "Effect": "Allow",
    "Action": "sqs:ListQueues",
    "Resource": "*"
  }
```
