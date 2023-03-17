# CloudWatch Agent Example

This is an example of how to setup the CloudWatch Agent to send metrics to CloudWatch and your log data to CloudWatch
Logs using the following modules:

* [cloudwatch-agent](/modules/agents/cloudwatch-agent): Scripts to install and configure the CloudWatch Unified Agent.
* [cloudwatch-log-aggregation-iam-policy](/modules/logs/cloudwatch-log-aggregation-iam-policy): A module that defines
  an IAM policy that allows reading/writing CloudWatch log data.
* [cloudwatch-custom-metrics-iam-policy](/modules/metrics/cloudwatch-custom-metrics-iam-policy): A module that defines
  an IAM policy that allows reading/writing CloudWatch metrics.


## Quick start

To try these templates out you must have Terraform installed (minimum version: `1.0.0`):

1. Build an AMI using the [Packer](https://www.packer.io/) template under `packer/build.json`.
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including setting `ami` to the AMI you built in step 1.
1. Run `terraform init`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

## How do I see the CloudWatch Logs?

Visit the [CloudWatch Logs Dashboard](https://console.aws.amazon.com/cloudwatch/home#logs:) and look for the log group
name `<name>-logs` (e.g. `cloudwatch-log-aggregation-example-logs`).
