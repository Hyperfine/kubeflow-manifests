# CloudWatch Alarms to Slack

This is an example of how to configure a [Slack webhook integration](https://api.slack.com/incoming-webhooks) for your CloudWatch alarms.

## Quick start

This module builds off of any existing CloudWatch alarm configurations, such as [ec2-cpu-alarms](/modules/alarms/ec2-cpu-alarms) or [alb-alarms](/modules/alarms/alb-alarms).

The example extends the [EC2 Alarms Example](/examples/alarms/ec2-alarms) to avoid duplication. If you are starting from scratch, please check the readme for that module to ensure it is configured properly.

After you have CloudWatch alarms configured and sending notifications to an SNS Topic, the next step is connecting that topic to the [sns_to_slack](/modules/alarms/sns-to-slack) module. This is the glue that takes notifications from the SNS topic and forwards them to your Slack channel.

1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
