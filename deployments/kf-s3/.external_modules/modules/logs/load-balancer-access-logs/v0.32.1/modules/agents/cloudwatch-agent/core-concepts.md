# Operations

## How to install the cloudwatch-agent on your EC2 Instances?

To install the CloudWatch Unified Agent on your EC2 Instances, you need to:

1. Copy the default configuration (`config.json`) to each instance.
1. Run `install-cloudwatch-agent.sh` on each instance.
1. Copy `restart-cloudwatch-agent.sh` to each instance.
1. (If you wish to dynamically configure the agent at boot time) Copy `configure-cloudwatch-agent.sh` to each instance.

Note that all of these steps can be handled for you automatically using the [Gruntwork
Installer](https://github.com/gruntwork-io/gruntwork-installer):

```bash
gruntwork-install \
    --module-name `agents/cloudwatch-agent` \
    --module-param aws-region=us-east-1 \
    --repo 'https://github.com/gruntwork-io/terraform-aws-monitoring'
```

The best way to do these two steps is in a [Packer template](https://www.packer.io/). See the
[cloudwatch-agent example](/examples/cloudwatch-agent) for an example.

## How to configure the cloudwatch-agent on your EC2 Instances?

When you install the cloudwatch-agent using the provided scripts, a default configuration is installed for the agent.
This default configuration contains the following setup:

- Run the agent as `root`.

- Ship the following metrics to CloudWatch using the dimensions AMI ID, Instance ID, Instance Type, and (if available)
  Auto Scaling Group Name:
    - CPU system, user, and idle usage
    - Memory usage information
    - Swap memory usage information
    - Disk usage information for `/` and `/tmp`
    - Disk I/O metrics (number of reads, writes, time spent on I/O)

- Do not collect any logs.

You can further customize this default configuration at runtime using the provided `configure-cloudwatch-agent.sh` script. This
script allows you to update the configuration to:

- Run the agent as a different OS user.
- Specify log files to ship to CloudWatch Logs.
- Specify which CloudWatch Log Group and Log Stream to use for shipping the logs
- Disable detailed metrics collection. You can disable the reported metrics using the following flags:
    - `--disable-cpu-metrics`: Disable CPU usage metrics
    - `--disable-mem-metrics`: Disable memory and swap usage metrics.
    - `--disable-disk-metrics`: Disable disk usage and I/O metrics.

If there are other configuration options you wish to update, we recommend generating a new configuration file using the
[CloudWatch Agent Configuration File
Wizard](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file-wizard.html)
provided by AWS and uploading it to `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json` on the server
when you are setting up the AMI with `packer`.

## How do I specify what logs go to specific streams?

You can use the provided `configure-cloudwatch-agent.sh` script to customize what logs go to CloudWatch Logs. For
example, to configure the agent to ship the user data and syslog entries to the log group `server-logs` and log stream
`{instance_id}-syslog`, you would make the following call in your user-data script for the EC2 instance:

```
/etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh --syslog --log-file /var/log/user-data.log \
  --log-group-name 'server-logs' --log-stream-name '{instance_id}-syslog'
```

You can pass in the `--log-file` option multiple times for different log files. The option also supports glob syntax.
For example, if you wish to ship all logs in the `/var/logs` folder:

```
/etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh --log-file /var/log/*.log \
  --log-group-name 'server-logs' --log-stream-name '{instance_id}-logs'
```

Note that you can only configure a single log stream per call to `configure-cloudwatch-agent.sh`. However, you can call
the command multiple times to configure different streams. For example, to configure syslog to go to the stream
`{instance_id}-syslog` and the auth logs to go to the stream `{instance_id}-authlogs`, you would call the script twice:

```
/etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh --syslog \
  --log-group-name 'server-logs' --log-stream-name '{instance_id}-syslog'
/etc/user-data/cloudwatch-agent/configure-cloudwatch-agent.sh --authlog \
  --log-group-name 'server-logs' --log-stream-name '{instance_id}-authlogs'
```


## What IAM permissions are necessary for the Agent to operate?

The EC2 instances will need IAM permissions to report the metrics and logs to CloudWatch. You can use the
[logs/cloudwatch-log-aggregation-iam-policy](/modules/logs/cloudwatch-log-aggregation-iam-policy) and
[metrics/cloudwatch-custom-metrics-iam-policy](/modules/metrics/cloudwatch-custom-metrics-iam-policy) modules to
configure the IAM role with permissions to ship logs and report metrics to CloudWatch.
