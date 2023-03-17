# Simple Notification Service (SNS) Topic Module 

This module makes it easy to deploy a SNS topic along with the publisher and subscriber policies for the topic.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.

Here is an example of how you might deploy an SNS topic with this module:

```hcl
module "sns" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-messaging.git//modules/sns?ref=v0.0.1"

  name = "my-topic"
  display_name = "my-display"
  allow_publish_accounts = [
     "arn:aws:iam::123456789012:user/Bill",
     "arn:aws:iam::123456789012:user/Ted"
  ]
  
  allow_subscribe_accounts = [
     "arn:aws:iam::123456789012:user/AbeLincoln"
  ]
  
  allow_subscribe_protocols = [
    "https"
  ]

  allow_publish_services = [
    "events.amazonaws.com",
    "rds.amazonaws.com"
  ]
}
```

## How do I access the SNS topic?

This module includes several [Terraform outputs](https://www.terraform.io/intro/getting-started/outputs.html),
including:

1. `topic_arn`: The ARN of the created topic
