# CloudWatch Log Aggregation IAM Policy

This module contains Terraform templates that define an [IAM
policy](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html#d0e22325) required
for CloudWatch Logging. You can attach this IAM policy to any EC2 Instances that need to send their logs to CloudWatch.
See the [cloudwatch-log-aggregation-scripts module](../cloudwatch-log-aggregation-scripts) for scripts you can use to
configure your EC2 Instances to do CloudWatch Log Aggregation.

## Example

See the [cloudwatch-log-aggregation example](/examples/cloudwatch-log-aggregation) for an example of how to use this
module.

## How do you use this module?

To set up CloudWatch Log Aggregation, you need to do two things:

1. Run the CloudWatch Logs Agent on your EC2 Instances
2. Provide your EC2 Instances with an IAM policy

Both are described next.

#### Run the CloudWatch Logs Agent on your EC2 Instances

To send log information to CloudWatch, you should use the [CloudWatch Logs
Agent](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html). The best way to
install it on your EC2 Instances is to use the [cloudwatch-log-aggregation-scripts
module](../cloudwatch-log-aggregation-scripts), which have scripts for installing and running the CloudWatch Logs
Agent.

#### Provide your EC2 Instances with an IAM policy

To allow your EC2 Instances to talk to CloudWatch Logs, you need the right IAM policy. The Terraform templates in this
module create this policy up for you. You just need to use an
[aws_iam_policy_attachment](https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html) to attach that
policy to the IAM roles of your EC2 Instances.

```hcl
module "cloudwatch_log_aggregation" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/cloudwatch-log-aggregation-iam-policy?ref=v0.0.18"
}

resource "aws_iam_policy_attachment" "attach_cloudwatch_log_aggregation_policy" {
    name = "attach-cloudwatch-log-aggregation-policy"
    roles = ["${aws_iam_role.my_ec2_instance_iam_role.id}"]
    policy_arn = "${module.cloudwatch_log_aggregation.cloudwatch_log_aggregation_policy_arn}"
}
```
