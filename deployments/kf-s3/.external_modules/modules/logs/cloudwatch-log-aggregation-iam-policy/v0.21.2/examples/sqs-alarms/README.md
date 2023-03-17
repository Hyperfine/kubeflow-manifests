# SQS Alarms Example

This is an example of how to set up alarms for an Simple Queue Service (SQS) queue using the following modules:

* [sqs-alarms](/modules/alarms/sqs-alarms): Alarms for an SQS queue that go off if the number of visible messages is too high or age of oldest message surpasses the threshold.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `0.6.11`):

1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
2. Run `terraform get`.
3. Run `terraform plan`.
4. If the plan looks good, run `terraform apply`.

## How do I get notifications from these alarms?

This example configures the CloudWatch alarms to send notifications to an [SNS](https://aws.amazon.com/sns/) topic
whenever the state of the alarm changes. You can subscribe to this topic to receive notifications via email and/or
SMS:

1. When you run `terraform apply`, or, later, if you run `terraform output`, the name and ARN of this topic will be
   outputted to the console.
2. Login to the [SNS console](https://console.aws.amazon.com/sns/v2/home).
3. Click the "Topics" link in the menu on the left.
4. Find the topic with the name and ARN from step 1 in the list and click the checkbox next to it.
5. Click the "Actions" button and select "Subscribe to Topic".
6. Choose "Email" or "SMS Message" as the protocol, enter your email or phone number, and click "Create Subscription".
7. AWS will email or message you to confirm the subscription. Be sure to confirm it, or you won't receive any
   notifications, and the alarm will report its status as `INSUFFICIENT_DATA`!