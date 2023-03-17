# CloudWatch Custom Metrics IAM Policy

This module contains Terraform templates that define an [IAM
policy](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html#d0e22325) required
for reading and writing CloudWatch metrics. You can attach this IAM policy to any EC2 Instances that need CloudWatch
metrics.

Note: CloudWatch provides many metrics for your EC2 Instances by default, but not memory and disk usage metrics. See the
[cloudwatch-agent module](../../agents/cloudwatch-agent) for scripts you can use to
configure your EC2 Instances to report memory and disk usage metrics as well.

## Example

See the [cloudwatch-agent example](/examples/cloudwatch-agent) for an example of how to use this
module.

## How do you use this module?

The basic idea is to add the module to your Terraform templates and then to use an
[aws_iam_policy_attachment](https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html) to attach the IAM
policy to the IAM roles of your EC2 Instances.

```hcl
module "cloudwatch_metrics" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/metrics/cloudwatch-custom-metrics-iam-policy?ref=v0.0.18"
}

resource "aws_iam_policy_attachment" "attach_cloudwatch_metrics_policy" {
    name = "attach-cloudwatch-metrics-policy"
    roles = ["${aws_iam_role.my_ec2_instance_iam_role.id}"]
    policy_arn = "${module.cloudwatch_metrics.cloudwatch_metrics_policy_arn}"
}
```
