# Elasticsearch Alarms Module

This module adds the [recommended CloudWatch alarms](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/cloudwatch-alarms.html)
for metrics produced by an [Amazon Elasticsearch Cluster](https://aws.amazon.com/elasticsearch-service/).

The alarms are for:
* Red or yellow cluster status
* Blocked cluster index writes
* Missing nodes (requires `var.instance_count` to be set)
* Automated snapshot failures
* Low disk space, high CPU or high memory pressure on the data nodes
* Low CPU credits (t instances only)
* High CPU or high memory pressure on the master nodes (optional if `var.monitor_master_nodes` is true)
* Inaccessible or disabled KMS keys (optional if `var.monitor_kms_key` is true)

See [Managing Amazon Elasticsearch Service
Domains](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html) for
more info.

## How do you use this module?

Check out the [examples/elasticsearch-alarms example](/examples/elasticsearch-alarms).

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
