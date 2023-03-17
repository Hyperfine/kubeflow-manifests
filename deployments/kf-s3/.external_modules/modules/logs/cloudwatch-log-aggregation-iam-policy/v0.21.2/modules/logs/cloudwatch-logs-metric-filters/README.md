# AWS CloudWatch Logs Metric Filters Terraform Module

This Terraform Module creates one or more[CloudWatch Logs Metric Filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html) using [log filter patterns](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html). The module will also create a metric alarms configured to push notifications to an SNS topic when the log filter patterns are matched.

## Quick Start

See the [CloudWatch Logs Filter example](/examples/cloudwatch-logs-metric-filters) in this repo for an example of how to use the module.

## Resources Created
* `aws_cloudwatch_log_metric_filter` - A metric filter applied to the passed CloudWatch Logs Group
* `aws_cloudwatch_metric_alarm` - An optional alarm associated with the new metric

## What are CloudWatch Logs Metric Filters?
CloudWatch Logs Metric Filters are a feature to search the streams of a CloudWatch Log group for a specified pattern. If the pattern matches, a CloudWatch Metric associated with the pattern is increased by the given value. This allows you to build graphs or to set alarms associated with the events in your logs.

For example, consider the following log entry from CloudTrail (slightly edited for clarity):

```json
{
    "userIdentity": {
        "type": "Root",
        "principalId": "012345678901",
        "arn": "arn:aws:iam::012345678901:root",
        "accountId": "012345678901",
    },
    "eventTime": "2019-09-18T21:04:21Z",
    "eventSource": "signin.amazonaws.com",
    "eventName": "ConsoleLogin",
    "awsRegion": "us-east-1",
    "sourceIPAddress": "10.0.0.1",
    "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:69.0) Gecko/20100101 Firefox/69.0",
    "responseElements": {
        "ConsoleLogin": "Success"
    },
    "additionalEventData": {
        "MobileVersion": "No",
        "MFAUsed": "No"
    },
    "eventType": "AwsConsoleSignIn",
}
```

This CloudTrail event shows a console log in by the root user of the account. [AWS advises](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html) against using the root account, but it isn't possible to prevent root access at the account level. Instead, you can set up a CloudWatch Logs Metric Filter to send an alert if the event is matched.

## How do filter patterns work?
Filter patterns match values in log events. Patterns can match exact words, multiple terms, and can also parse JSON log events. For example, the following pattern would match the message above:

    { $.userIdentity.type = \"Root\" && $.eventType = \"AwsConsoleSignIn\"

In this module, you could match the event with the following `metric_map` variable definition:

    metric_map = {
      "RootUserConsoleSignIn" = {
        pattern = "{ $.userIdentity.type = \"Root\" && $.eventType = \"AwsConsoleSignIn\" }"
        description = "Root user signed in to the console"

      }
    }

Refer to the [AWS CloudWatch Logs Filter and Pattern syntax documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) for a complete guide.


## How does the metric alarm work?
This module automatically creates metric alarms for each filter. Each metric alarm will send notifications of state changes to an SNS topic. A state change occurs when the filter pattern is matched and the alarm threshold is breached for the given period. The alarm will enter the **Alarm** state and send a notification to the SNS topic. When the state is recovered, the alarm will enter the **OK** state and send another notification to the SNS topic.

The [`alarm_treat_missing_data` option](https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html#treat_missing_data) bears further explanation. When a filter pattern matches, it increments the given metric by 1 for each match. If no events are matching, the metric will not report any data at all. The `alarm_treat_missing_data` should be configured with the default setting of `notBreaching` to remain in the **OK** state when the no data is present. Acceptable values include: `missing`, `ignore`, `breaching` and `notBreaching`.

## SNS options
The module will create an SNS topic with the name passed in `sns_topic_name` unless `sns_topic_already_exists` is set, in which case the alarm will be configured to send notifications to the pre-existing SNS topic given in `sns_topic_arn`.

Note that the module **does not** create any subscriptions to the SNS topic.
