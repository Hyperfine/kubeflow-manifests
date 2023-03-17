# CloudWatch Log Aggregation Scripts

This module contains scripts to install and run the [CloudWatch Logs
Agent](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html) on your EC2
instances so that anything logged to [syslog](https://en.wikipedia.org/wiki/Syslog) is sent to [CloudWatch
Logs](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatchLogs.html). This allows you to
use CloudWatch for log aggregation, so instead of having to ssh to individual servers to grep their log files, you can
just login to the [CloudWatch Logs Dashboard](https://console.aws.amazon.com/cloudwatch/home#logs:) and search the
logs from all of your servers in one place.

## Example

See the [cloudwatch-log-aggregation example](/examples/cloudwatch-log-aggregation) for an example of how to use this
module.

## Setting up log aggregation

To set up log aggregation, you must do the following:

1. Install the CloudWatch Logs Agent on your EC2 Instances
2. Run the CloudWatch Logs Agent on your EC2 Instances
3. Add IAM permissions to your EC2 Instances
4. Configure your app to log to syslog

All of these are described in detail next.

#### Install the CloudWatch Logs Agent on your EC2 Instances

To install the CloudWatch Logs Agent on your EC2 Instances, you need to:

1. Run `install-cloudwatch-logs-agent.sh` on each instance.
2. Copy `run-cloudwatch-logs-agent.sh` to each instance.

Note that both of these steps can be handled for you automatically using the
[Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer):

```bash
gruntwork-install --module-name `cloudwatch-log-aggregation` --module-param aws-region=us-east-1
```

The best way to do these two steps is in a [Packer template](https://www.packer.io/). See the
[cloudwatch-log-aggregation example](/examples/cloudwatch-log-aggregation) for an example.

## Run the CloudWatch Logs Agent on your EC2 Instances

When your EC2 Instances are booting up, they should run the `run-cloudwatch-logs-agent.sh` script, which will configure
and start the CloudWatch Logs Agent. The script supports three command line options:

* `--log-group-name`: The name to use for the log group. Required.
* `--log-stream-name`: The name to use for the log stream. Optional. Default: `{instance_id}`.

The best way to run a script during boot is to put it in [User
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts). Here's an example:

```bash
#!/bin/bash
/etc/user-data/cloudwatch-log-aggregation/run-cloudwatch-logs-agent.sh --log-group-name prod-ec2-syslog
```

By default, this will send all the logs in syslog to CloudWatch. If you want to send other log files too, you can
use the `--extra-log-file` parameter one or more times:

```
/etc/user-data/cloudwatch-log-aggregation/run-cloudwatch-logs-agent.sh --log-group-name prod-ec2-syslog --extra-log-file nginx-errors=/var/log/nginx/nginx_error.log
```

#### Add IAM permissions to your EC2 Instances

Your EC2 Instances need an [IAM policy](http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) that
allows them to [write to CloudWatch
Logs](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/QuickStartEC2Instance.html#d0e22325). The
[cloudwatch-log-aggregation-iam-policy module](../cloudwatch-log-aggregation-iam-policy) can add this policy for you
automatically.

#### Configure your app to log to syslog

Once you've completed the steps above, anything logged to [syslog](https://en.wikipedia.org/wiki/Syslog) will be sent
by the Logs Agent to CloudWatch. Therefore, you need to configure your application to log to syslog. How you do this
depends on the technologies you're using. Here are some links to get you started:

* [nginx](http://nginx.org/en/docs/syslog.html)
* [apache](https://httpd.apache.org/docs/2.2/en/logs.html)
* [docker](https://docs.docker.com/engine/admin/logging/overview/)
* [log4j](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/net/SyslogAppender.html)
* [logback](http://logback.qos.ch/manual/appenders.html#SyslogAppender)

#### Troubleshooting

If you are not seeing logs in CloudWatch, SSH to one of your instances and run the following command:

```
sudo service awslogs status
```

It should say "awslogs (pid  XXXX) is running..." You can also check the Logs Agent own log file for errors at:

```
vi /var/log/awslogs.log
```
