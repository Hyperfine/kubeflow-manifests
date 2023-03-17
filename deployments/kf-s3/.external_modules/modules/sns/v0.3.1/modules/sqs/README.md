# Simple Queuing Service (SQS) Module 

This module makes it easy to deploy an SQS queue along with policies for the topic.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.

## Deployment Examples

### Restrict Access Only By IP

An example with NO IAM AUTHENTICATION required, ONLY IP based restrictions are used. Allowed IPs based on the value of `var.allowed_cidr_blocks`

```hcl-terraform
module "sqs" {
  source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/sqs?ref=v0.1.4"

  name = "my-queue"

  apply_ip_queue_policy = true

  # Allow unauthenticated access from a CIDR block
  allowed_cidr_blocks = [
    "10.10.1.0/22"
  ]
  
  visibility_timeout_seconds = 60
  message_retention_seconds = 86400   #1 day
  max_message_size = 131072           #128kb
  delay_seconds = 10
  receive_wait_time_seconds = 20
  fifo_queue = true
}
```

### Require IAM Permissions for Queue Access

An example of a queue policy is not used and permissions to the queue are handled outside of this module in IAM policies attached to roles or users.

```hcl-terraform
module "sqs" {
  source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/sqs?ref=v0.1.4"

  name = "my-queue"
  
  visibility_timeout_seconds = 60
  message_retention_seconds = 86400   #1 day
  max_message_size = 131072           #128kb
  delay_seconds = 10
  receive_wait_time_seconds = 20
  fifo_queue = true
}
```

### Include a Dead Letter Queue

An example of how to use this module to create a queue with a dead-letter queue.

```hcl-terraform
module "sqs" {
  source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/sqs?ref=v0.1.4"

  name = "my-queue-with-dead-letter"
  dead_letter_queue = true
  max_receive_count = 10
}
```

## How do I access the SQS queue?

This module includes several [Terraform outputs](https://www.terraform.io/intro/getting-started/outputs.html),
including:

1. `queue_arn`: The ARN of the created queue
1. `dead_letter_queue_arn` The ARN of the dead letter queue
