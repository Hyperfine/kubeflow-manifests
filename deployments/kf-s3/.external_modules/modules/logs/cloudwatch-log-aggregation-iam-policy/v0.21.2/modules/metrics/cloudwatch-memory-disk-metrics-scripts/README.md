# CloudWatch Memory and Disk Metrics Scripts

By default, CloudWatch does not provide memory and disk usage metrics for your EC2 Instances. This is because EC2
instances are VMs and CloudWatch only has metrics from the hypervisor, which cannot see the memory and disk usage
metrics inside a running VM. To fill in this gap, Amazon provides the [CloudWatch Monitoring
Scripts](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html) which you can run directly
on your EC2 Instances. This module installs these scripts for you and configures them to run in a cron job so you get
regular reporting of memory and disk usage metrics.

Note, this module only supports the following Linux flavors:

* Amazon Linux 2
* Amazon Linux
* Ubuntu
* CentOS / Red Hat Linux

## Example

See the [cloudwatch-custom-metrics example](/examples/cloudwatch-custom-metrics) for an example of how to use this
module.

## Setting up memory and disk metrics in CloudWatch

To get memory and disk metrics in CloudWatch, you need to:

1. Install the CloudWatch Monitoring Scripts on your EC2 Instance
2. Add IAM permissions to your EC2 Instances

Both of these steps are described next.

#### Install the CloudWatch Monitoring Scripts on your EC2 Instance

To install the CloudWatch Monitoring Scripts, you need to run `install-cloudwatch-monitoring-scripts.sh`. Note that
this can be handled for you automatically using the
[Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer):

```bash
gruntwork-install --module-name `cloudwatch-memory-disk-metrics`
```

The script takes two parameters:

1. `cron-schedule`: The schedule on which metrics will be sent to CloudWatch. Must use [Cron
    Format](http://www.nncron.ru/help/EN/working/cron-format.htm). Default: `*/5 * * * *` (every 5 minutes).
2. `metrics-to-monitor`: A space-separated list of command line options to the CloudWatch Monitoring Scripts that
   identify the metrics you want monitored. See
   [here](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html#using_put_script_options)
   for a list of supported options. Also, be sure to check the [CloudWatch Custom Metrics
   Pricing](https://aws.amazon.com/cloudwatch/pricing/) so you know how much these metrics will cost you.
   Default: `--disk-path='/' --mem-util --disk-space-util --auto-scaling` (report disk space utilization percentage
   for `/` and memory utilization percentage; aggregate the metrics by auto scaling group).

For example, to send metrics every hour on the utilization percentage of the path `/foo` as well as all available
memory metrics, you would run:

```bash
gruntwork-install --module-name cloudwatch-memory-disk-metrics --module-param 'cron-schedule="0 * * * *"' --module-param "metrics-to-monitor='--disk-path=/ --mem-util --disk-space-util --auto-scaling'"
```

#### Add IAM permissions to your EC2 Instances

Your EC2 Instances need an [IAM policy](http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) that
allows them to [read and write CloudWatch
metrics](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html#d0e19889). The
[cloudwatch-custom-metrics-iam-policy module](../cloudwatch-custom-metrics-iam-policy) can add this policy for you
automatically.


#### Permit access to metadata service

If using the [ip-lockdown](https://github.com/gruntwork-io/module-security/tree/master/modules/ip-lockdown) module or similar mechanism to limit access to the EC2 metadata service, you must allow the `cwmonitoring` user access for the metrics script to identify the host. For example in your user data script:

```bash
ip-lockdown 169.254.169.254 root cwmonitoring
```

The user who is configured to run the metrics script can be changed at installation time with the `cron-user` installation parameter:

```bash
gruntwork-install --module-name cloudwatch-memory-disk-metrics --module-param 'cron-user="cloudwatch"'
```

## Viewing the metrics

Once this module is installed, to see the memory and disk usage metrics, login to the [CloudWatch Metrics
Dashboard](https://console.aws.amazon.com/cloudwatch/home#metrics:) and look for the "Linux System Metrics". Depending
on the `metrics-to-monitor` setting you used, these are the metrics you may find:

* DiskSpaceAvailable
* DiskSpaceUsed
* DiskSpaceUtilization
* MemoryAvailable
* MemoryUsed
* MemoryUtilization
* SwapUsed
* SwapUtilization
