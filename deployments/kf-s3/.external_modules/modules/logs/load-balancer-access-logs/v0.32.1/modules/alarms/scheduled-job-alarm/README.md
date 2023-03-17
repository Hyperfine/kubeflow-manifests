# Sheduled Job Alarm Module

This module creates an alarm that goes off if a specified metric drops below a specified threshold over a specified
time period. This is most useful for detecting if a scheduled job failed. For example, if you have a CRON job that runs
once per night, you could have the CRON job set a metric to the value "1" after each successful run and then use this
module to trigger an alarm if the metric drops below the value "1" over a 24 hour period. This module works especially
well with [ec2-snapper](https://github.com/josh-padnick/ec2-snapper), which you can run in a CRON job to automatically
backup EC2 Instances and write CloudWatch metrics.

## Example

Check out the [examples/scheduled-job-alarms example](/examples/scheduled-job-alarms).

## How do you use this module?

The basic idea is to use the `module` resource in your templates and to specify:

1. The name of your scheduled job
1. The namespace in CloudWatch for your metrics
1. The name of the metric that is incremented whenever the scheduled job runs
1. How often that metric should be updated
1. The ARN of an SNS topic to notify whenever the alarm goes into `OK` state, which indicates the scheduled job is
   working, or `INSUFFICIENT_DATA` state, which indicates the metric is not being written, and therefore the scheduled
   job is probably failing.

Example:

```hcl
module "scheduled_job_alarm" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/scheduled-job-alarm?ref=v1.0.8"

  name = "my-scheduled-job-foo"
  namespace = "MyScheduledJobs"
  metric_name = "ScheduledJobFoo"
  alarm_sns_topic_arns = "${aws_sns_topic.cloudwatch_alarms.arn}"

  # We expect the job to run once per day, which is 86,400 seconds. However, the job itself may take some time to run,
  # so we add two hours (7200 seconds) of buffer room and expect the metric to be updated once every 93,600 seconds.
  period = 93600
}

# Create an SNS topic that will be notified whenever this alarm is in OK or INSUFFICIENT_DATA state. You can subscribe
# to notifications from this SNS topic by email or text message.
resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "my-scheduled-job-cloudwatch-alarms"
}
```

See [variables.tf](./variables.tf) for documentation on all the parameters you can set in this module.

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
