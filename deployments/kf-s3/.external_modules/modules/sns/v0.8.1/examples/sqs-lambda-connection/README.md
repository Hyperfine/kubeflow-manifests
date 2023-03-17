# Simple Queuing Service (SQS) to Lambda Trigger Connector

This folder shows an example of how to use the [sqs-lambda-connection module](./modules/sqs-lambda-connection) to have a Lambda process Queue messages


## Quick start

To try these templates out you must have Terraform installed:

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform init`.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

Here is an example of how you might use a SQS to trigger a Lambda to process the queue:

```hcl
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sns-lambda-connection?ref=v0.0.1"
}

dependency "lambda" {
  config_path = "${get_terragrunt_dir()}/../../lambdas/myLambda"
}

dependency "sqs-queue" {
  config_path = "${get_terragrunt_dir()}/../../sqs/srcQueue"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  lambda_arn = dependency.lambda.outputs.function_arn
  sqs_arn    = dependency.sqs-queue.outputs.queue_arn
}
```
