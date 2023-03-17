# Route53 Health Check Alarms

This is an example of how to set up Route 53 health checks for a domain using the following modules:

* [route53-health-check-alarms](/modules/alarms/route53-health-check-alarms): Monitor a given domain (e.g. example.com)
  using Route 53 and trigger an alarm if that domain is down or unresponsive.

**NOTE**: Route 53 only sends CloudWatch metrics to `us-east-1`. Therefore, we must create the health check and alarm in
that region. Moreover, the SNS Topic ARNs you pass in must ALSO be in `us-east-1`. Otherwise, you'll get the error
`Invalid region us-XXXX-Y specified. Only us-east-1 is supported.` For more info, see:
https://github.com/hashicorp/terraform/issues/7371.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `0.6.11`):

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

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