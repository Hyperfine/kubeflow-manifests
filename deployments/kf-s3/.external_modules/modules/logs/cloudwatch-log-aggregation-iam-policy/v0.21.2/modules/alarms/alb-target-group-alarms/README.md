# ALB Target Group Alarms

This module adds alarms for metrics produced by an [ALB Target Group](
http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html). They will go off 
if there are a surge in requests, too many 4xx or 5xx errors, too many errors connecting to Targets or Targets are
 taking too long to respond. Some of these indicate you have experienced a significant scaling event. Others
suggest that something is going wrong with your servers.

**Note**: The `tg_high_http_code_target_4xx_count`, `tg_high_http_code_target_5xx_count`, and 
`tg_high_target_connection_error_count` alarms all monitor metrics that are only reported when there are errors. If 
 there are no errors, those metrics are not reported at all, and the alarm goes into an `INSUFFICIENT_DATA` state. This 
 actually means everything is working OK. It's only when these alarms enter `ALARM` state that you need to look into it.

## How do you use this module?

Check out the [examples/alb-target-group-alarms example](/examples/alb-target-group-alarms).

## How do I get notifications from these alarms?

One of the parameters you pass to this module is a list of [SNS](https://aws.amazon.com/sns/) topic ARNs to notify when
the website goes down. Here is how to configure an SNS topic:

1. Create an SNS topic using the Terraform [aws_sns_topic](https://www.terraform.io/docs/providers/aws/r/sns_topic.html) resource.
2. Pass the topic's ARN to this module (e.g. `alarm_sns_topic_arns = "${aws_sns_topic.my_topic.arn}"`)
3. Login to the [SNS console](https://console.aws.amazon.com/sns/v2/home).
4. Click the "Topics" link in the menu on the left.
5. Find your topic in the list and click the checkbox next to it.
6. Click the "Actions" button and select "Subscribe to Topic".
7. Choose "Email" or "SMS Message" as the protocol, enter your email or phone number, and click "Create Subscription".
8. AWS will email or message you to confirm the subscription. Be sure to confirm it, or you won't receive any
   notifications, and the alarm will report its status as `INSUFFICIENT_DATA`!
