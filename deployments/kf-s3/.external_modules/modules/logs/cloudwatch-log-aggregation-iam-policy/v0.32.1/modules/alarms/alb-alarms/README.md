# ALB Alarms Module

This module adds alarms for metrics produced by an [ALB](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html). 
They will go off if there are a surge in connections, any client TLS negotiation errors, too many 4xx or 5xx errors, or 
more requests than your ALB can handle. Some of these indicate you have experienced a significant scaling event. Others
suggest that something is going wrong with your servers.

**Note**: The `alb_high_client_tls_negotiation_error_count`, `alb_high_http_code_4xx_count`, `alb_high_http_code_5xx_count`
 and `alb_high_rejected_connection_count` alarms all monitor metrics that are only reported when there are errors. If 
 there are no errors, those metrics are not reported at all,and the alarm goes into an `INSUFFICIENT_DATA` state. This 
 actually means everything is working OK. It's only when hese alarms enter `ALARM` state that you need to look into it.

## How do you use this module?

Check out the [examples/alb-alarms example](/examples/alb-alarms).

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

## FAQs

### Do these alarms use the most granular CloudWatch metrics available?

In some cases, they do not! Any CloudWatch Metric may be filtered along one or more "Dimensions". These Dimensions are 
defined by Amazon and depend on the semantic meaning of the CloudWatch Metric.

For example, you can define a visual graph or set an alarm on the `RequestCount` metric to see all requests
 made to a single [ALB](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) over a 
given period of time. But you can further narrow this data to use a specific [Target Group]
(http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) and narrow it further 
still to a specific Availability Zone.

Amazon defines each of these filters as a "Metric Dimension" and you can look them up for any CloudWatch Metric. For 
example, to see the Dimensions for the ALB, see https://goo.gl/8ih8rP.
  
When you define an alarm for a CloudWatch Metric, in some cases, there is no decision on which Dimensions to use. For
example, the `HTTPCode_ELB_5XX_Count` metric reports the number of HTTP 5XX server error codes that originate from the 
ALB (not an ELB, as indicated in the name). Although it may be conceivable to further narrow this by Target Group or 
Availability Zone, there are other metrics that report that information, so the only valid dimension for this metric is
 `LoadBalancer`.
 
Each of the CloudWatch alarms defined in this `alb-alarms` module use only the `LoadBalancer` dimension. Each of the 
CloudWatch alarms defined in the `alb-target-group-alarms` module use both the `LoadBalancer` dimension and the `TargetGroup`
dimension.
