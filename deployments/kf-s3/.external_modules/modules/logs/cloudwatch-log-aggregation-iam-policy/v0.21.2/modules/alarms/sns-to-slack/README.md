# SNS to Slack Module

This module can be used to setup an integration between SNS and Slack.

An example use case for this module is forwarding CloudWatch alerts to a chatroom, but this module will send any notification put into the SNS topic to the slack webhook.


## How do you use this module

Check out the [examples/cloudwatch-to-slack example](/examples/cloudwatch-to-slack) for an example of sending alarms to Slack.

At a high level, two things are required to make this work:

1. An SNS Topic
2. A Slack Webhook URL

An AWS Lambda function is used as the glue to connect the SNS topic to your Slack channel.


## How do I configure my connection to Slack?

1. Visit the apps area of your Slack settings. This will be something like https://<your-team>.slack.com/apps
2. Search for `Incoming Webhooks` and then choose `Add Configuration`
3. Set the options to your liking, and then copy the Webhook URL to use in this module.

Some of the options that you can configure are:

- The channel that SNS messages will appear in
- The name and icon for the incoming messages

The webhook URL will look something like `https://hooks.slack.com/services/FOO/BAR/BAZ`


